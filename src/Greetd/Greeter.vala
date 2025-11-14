public class Greeter.Greetd.Greeter : Object {
    
    private Socket? connect_to_greetd () {
        unowned var greetd_sock = Environment.get_variable ("GREETD_SOCK");
        if (greetd_sock == null) {
            critical ("GREETD_SOCK is unset");
            return null;
        }

        try {
            var address = new UnixSocketAddress (greetd_sock);

            var socket = new Socket (UNIX, STREAM, UNKNOWN);
            socket.connect (address, null);

            return socket;
        } catch (Error e) {
            critical ("Unable to open socket");
            return null;
        }
    }

    private int send_request (Json.Node request) {
        var socket = connect_to_greetd ();
        if (socket == null) {
            critical ("Couldn't send request: socket is null");
            return -1;
        }

        unowned var request_string = request.get_string ();
        if (request_string == null) {
            return -1;
        }

        // greetd max request length
        if (request_string.length > 0xFFFFFFFF) {
            return -1;
        }

        var header_int = request_string.length;
        uint8[] header_uint8 = {
            (uint8) ((header_int >> 24) & 0xFF),
            (uint8) ((header_int >> 16) & 0xFF),
            (uint8) ((header_int >> 8) & 0xFF),
            (uint8) ((header_int >> 0) & 0xFF)
        };
        
        var offset = 0;
        while (offset < 4) {
            try {
                offset += (int) socket.send (header_uint8[offset : 4], null);
            } catch (Error e) {
                return -1;
            }
        }

        offset = 0;
        while (offset < request_string.length) {
            try {
                offset += (int) socket.send (request_string.data[offset : request_string.length - offset], null);
            } catch (Error e) {
                return -1;
            }
        }

        return 0;
    }

    private Json.Node? receive_response () {
        var socket = connect_to_greetd ();
        if (socket == null) {
            critical ("Couldn't receive response: socket is null");
            return null;
        }

        // Read message length which is a 32 bit uint
        // socket allows us to read only 8 bytes at a time
        uint8[] length_buf = new uint8[4];
        var offset = 0;
        while (offset < 4) {
            try {
                var n = socket.receive (length_buf[offset : 4], null);
                if (n == 0) {
                    critical ("Connection closed or read error");
                    return null;
                }

                offset += (int) n;
            } catch (Error e) {
                critical ("Socket read failed: %s", e.message);
                return null;
            }
        }

        uint32 length = 0;
        length |= ((uint32) length_buf[0]) << 24;
        length |= ((uint32) length_buf[1]) << 16;
        length |= ((uint32) length_buf[2]) << 8;
        length |= ((uint32) length_buf[3]);

        uint8[] response_data = new uint8[length];
        offset = 0;
        while (offset < length) {
            try {
                var n = socket.receive(response_data[offset : length]);
                if (n == 0) {
                    critical ("Connection closed or read error");
                    return null;
                }

                offset += (int) n;
            } catch (Error e) {
                critical ("Socket read failed: %s", e.message);
                return null;
            }
        }

        try {
            var parser = new Json.Parser();
            parser.load_from_data((string) response_data, -1);
            return parser.get_root();
        } catch (Error e) {
            critical ("JSON parse failed: %s", e.message);
            return null;
        }
    }

    private Json.Node? roundtrip_json (Json.Node request) {
        if (send_request (request) != 0) {
            critical ("Couldn't send response to socket");
            return null;
        }

        var response = receive_response ();
        if (response == null) {
            critical ("Couldn't read response from socket");
            return null;
        }

        return response;
    }

    public Response roundtrip (Request request) {
        var json_builder = new Json.Builder ();

        switch (request.request_type) {
            case CREATE_SESSION:
                json_builder.begin_object ();
                json_builder.set_member_name ("type");
                json_builder.add_string_value ("create_session");
                json_builder.set_member_name ("username");
                json_builder.add_string_value (request.body);
                json_builder.end_object ();
                break;
            case START_SESSION:
                json_builder.begin_object ();
                json_builder.set_member_name ("type");
                json_builder.add_string_value ("start_session");
                json_builder.set_member_name ("cmd");
                json_builder.begin_array ();
                json_builder.add_string_value (request.body);
                json_builder.end_array ();
                json_builder.end_object ();
                break;
            case POST_AUTH_MESSAGE_RESPONSE:
                json_builder.begin_object ();
                json_builder.set_member_name ("type");
                json_builder.add_string_value ("post_auth_message_response");
                json_builder.set_member_name ("response");
                json_builder.add_string_value (request.body);
                json_builder.end_object ();
                break;
            case CANCEL_SESSION:
                json_builder.begin_object ();
                json_builder.set_member_name ("type");
                json_builder.add_string_value ("cancel_session");
                json_builder.end_object ();
                break;
        }

        var root_node = json_builder.get_root ();
        assert(root_node != null);

        var json_response = roundtrip_json (root_node);
        if (json_response == null) {
            critical ("Roundtrip failed");
            return new ResponseRoundtripError ();
        }

        if (json_response.get_node_type () != OBJECT) {
            critical ("Roundtrip: Unknown format");
            return new ResponseRoundtripError ();
        }

        var json_object = json_response.get_object ();
        assert (json_object != null);

        if (!json_object.has_member ("type")) {
            critical ("Roundtrip: No type specified");
            return new ResponseRoundtripError ();
        }

        switch (json_object.get_string_member ("type")) {
            case "success":
                return new ResponseSuccess ();
            case "auth_message":
                if (!json_object.has_member ("auth_message_type")) {
                    critical ("Roundtrip: No auth message type specified");
                    return new ResponseRoundtripError ();
                }

                ResponseAuthMessage.MessageType message_type;
                switch (json_object.get_string_member_with_default ("auth_message_type", "")) {
                    case "visible":
                        message_type = VISIBLE;
                        break;
                    case "secret":
                        message_type = SECRET;
                        break;
                    case "info":
                        message_type = INFO;
                        break;
                    case "error":
                        message_type = ERROR;
                        break;
                    default:
                        critical ("Roundtrip: Unknown message type");
                        return new ResponseRoundtripError ();
                }

                unowned var message = json_object.get_string_member_with_default ("auth_message", "");

                return new ResponseAuthMessage (message_type, message);
            case "error":
                unowned var description = json_object.get_string_member_with_default ("description", "");

                ResponseError.ErrorType error_type = ERROR;
                if (json_object.get_string_member_with_default ("error_type", "") == "auth_error")  {
                    error_type = AUTH;
                }

                return new ResponseError (error_type, description);
            default:
                critical ("Roundtrip: Type is unknown");
                return new ResponseRoundtripError ();
        }
    }
}
