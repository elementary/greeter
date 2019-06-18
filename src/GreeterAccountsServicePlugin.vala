[DBus (name = "io.elementary.greeter.AccountsService")]
interface Greeter.AccountsService : Object {
    public abstract string time_format { owned get; set; }
}
