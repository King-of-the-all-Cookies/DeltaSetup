using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace DeltaPatcherCLI
{
    internal class Win32API
    {
        internal enum MessageBoxButtons
        {
            /// <summary>
            /// The message box contains three push buttons: Abort, Retry, and Ignore.
            /// </summary>
            AbortRetryIgnore = 0x00000002,

            /// <summary>
            /// The message box contains three push buttons: Cancel, Try Again, Continue.
            /// </summary>
            CancelTryIgnore = 0x00000006,

            /// <summary>
            /// Adds a Help button to the message box.
            /// </summary>
            Help = 0x00004000,

            /// <summary>
            /// The message box contains one push button: OK. This is the default.
            /// </summary>
            Ok = 0x00000000,

            /// <summary>
            /// The message box contains two push buttons: OK and Cancel.
            /// </summary>
            OkCancel = 0x00000001,

            /// <summary>
            /// The message box contains two push buttons: Retry and Cancel.
            /// </summary>
            RetryCancel = 0x00000005,

            /// <summary>
            /// The message box contains two push buttons: Yes and No.
            /// </summary>
            YesNo = 0x00000004,

            /// <summary>
            /// The message box contains three push buttons: Yes, No, and Cancel.
            /// </summary>
            YesNoCancel = 0x00000003
        }

        /// <summary>
        /// The message box returns an integer value that indicates which button the user clicked.
        /// </summary>
        internal enum MessageBoxResult
        {
            /// <summary>
            /// The 'Abort' button was selected.
            /// </summary>
            Abort = 3,

            /// <summary>
            /// The 'Cancel' button was selected.
            /// </summary>
            Cancel = 2,

            /// <summary>
            /// The 'Continue' button was selected.
            /// </summary>
            Continue = 11,

            /// <summary>
            /// The 'Ignore' button was selected.
            /// </summary>
            Ignore = 5,

            /// <summary>
            /// The 'No' button was selected.
            /// </summary>
            No = 7,

            /// <summary>
            /// The 'OK' button was selected.
            /// </summary>
            Ok = 1,

            /// <summary>
            /// The 'Retry' button was selected.
            /// </summary>
            Retry = 10,

            /// <summary>
            /// The 'Yes' button was selected.
            /// </summary>
            Yes = 6
        }

        /// <summary>
        /// To indicate the default button, specify one of the following values.
        /// </summary>
        internal enum MessageBoxDefaultButton : uint
        {
            /// <summary>
            /// The first button is the default button.
            /// </summary>
            Button1 = 0x00000000,

            /// <summary>
            /// The second button is the default button.
            /// </summary>
            Button2 = 0x00000100,

            /// <summary>
            /// The third button is the default button.
            /// </summary>
            Button3 = 0x00000200,

            /// <summary>
            /// The fourth button is the default button.
            /// </summary>
            Button4 = 0x00000300
        }

        /// <summary>
        /// To display an icon in the message box, specify one of the following values.
        /// </summary>
        public enum MessageBoxIcon : uint
        {
            /// <summary>
            /// An exclamation-point icon appears in the message box.
            /// </summary>
            Warning = 0x00000030,

            /// <summary>
            /// An icon consisting of a lowercase letter `i` in a circle appears in the message box.
            /// </summary>
            Information = 0x00000040,

            /// <summary>
            /// A question-mark icon appears in the message box.
            /// </summary>
            /// <remarks>
            /// The question-mark message icon is no longer recommended because it does not clearly represent a specific type of message and because the phrasing of a message as a question could apply to any message type. In addition, users can confuse the message symbol question mark with Help information. Therefore, do not use this question mark message symbol in your message boxes. The system continues to support its inclusion only for backward compatibility.
            /// </remarks>
            Question = 0x00000020,

            /// <summary>
            /// A stop-sign icon appears in the message box.
            /// </summary>
            Error = 0x00000010
        }

        [DllImport("user32.dll")]
        internal static extern int MessageBoxA(IntPtr hWnd, string lpText, string lpCaption, uint uType);

        internal static MessageBoxResult ShowMessageBox(string text, string caption, MessageBoxButtons buttons, MessageBoxIcon icon)
        {
            return (MessageBoxResult)MessageBoxA(IntPtr.Zero, text, caption, ((uint)buttons) | ((uint)icon));
        }

        public static void ShowMessage(string message)
        {
            ShowMessageBox(message, "Сообщение", MessageBoxButtons.Ok, MessageBoxIcon.Information);
        }
        public static void ShowWarning(string message)
        {
            ShowMessageBox(message, "Предупреждение", MessageBoxButtons.Ok, MessageBoxIcon.Warning);
        }
    }
}
