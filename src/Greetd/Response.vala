public abstract class Greeter.Greetd.Response : Object {}

public class Greeter.Greetd.ResponseRoundtripError : Response {}

public class Greeter.Greetd.ResponseSuccess : Response {}

public class Greeter.Greetd.ResponseError : Response {
    public enum ErrorType {
        ERROR,
        AUTH
    }

    public ErrorType error_type { get; construct; }
    public string description { get; construct; }

    public ResponseError (ErrorType error_type, string description) {
        Object (error_type: error_type, description: description);
    }
}

public class Greeter.Greetd.ResponseAuthMessage : Response {
    public enum MessageType {
        VISIBLE,
        SECRET,
        INFO,
        ERROR
    }

    public MessageType message_type { get; construct; }
    public string message { get; construct; }

    public ResponseAuthMessage (MessageType message_type, string message) {
        Object (message_type: message_type, message: message);
    }
}
