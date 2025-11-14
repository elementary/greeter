public enum Greeter.Greetd.RequestType {
    CREATE_SESSION,
	START_SESSION,
	POST_AUTH_MESSAGE_RESPONSE,
	CANCEL_SESSION
}

// Replace with hierachy
public struct Greeter.Greetd.Request {
    RequestType request_type;
    string body;
}
