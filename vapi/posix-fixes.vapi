[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixMLock
{
    [CCode (cheader_filename = "sys/mman.h")]
    public const int MCL_CURRENT;
    [CCode (cheader_filename = "sys/mman.h")]
    public const int MCL_FUTURE;
    [CCode (cheader_filename = "sys/mman.h")]
    public int mlockall (int flags);
    [CCode (cheader_filename = "sys/mman.h")]
    public int munlockall ();
}
