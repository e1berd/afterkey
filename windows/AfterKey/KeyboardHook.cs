using System.Diagnostics;
using System.Runtime.InteropServices;

namespace AfterKey;

public sealed class KeyboardHook : IDisposable
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;

    public event Action<string>? KeyPressed;

    private IntPtr _hookId;
    private readonly LowLevelKeyboardProc _proc;

    public KeyboardHook() => _proc = HookCallback;

    public void Start()
    {
        using var process = Process.GetCurrentProcess();
        using var module = process.MainModule!;
        _hookId = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(module.ModuleName), 0);
    }

    public void Dispose()
    {
        if (_hookId == IntPtr.Zero) return;
        UnhookWindowsHookEx(_hookId);
        _hookId = IntPtr.Zero;
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN))
        {
            var vk = Marshal.ReadInt32(lParam);

            if (!KeyMap.IsModifier(vk))
            {
                var name = KeyMap.GetName(vk);
                if (name is not null)
                {
                    var mods = AppSettings.Instance.ShowModifiers ? ModifierPrefix() : "";
                    KeyPressed?.Invoke(mods + name);
                }
            }
        }

        return CallNextHookEx(_hookId, nCode, wParam, lParam);
    }

    private static string ModifierPrefix()
    {
        var parts = new List<string>(4);
        if (IsDown(0x5B) || IsDown(0x5C)) parts.Add("Win+");
        if (IsDown(0xA2) || IsDown(0xA3)) parts.Add("Ctrl+");
        if (IsDown(0xA4) || IsDown(0xA5)) parts.Add("Alt+");
        if (IsDown(0xA0) || IsDown(0xA1)) parts.Add("Shift+");
        return string.Concat(parts);
    }

    private static bool IsDown(int vk) => (GetAsyncKeyState(vk) & 0x8000) != 0;

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")] private static extern IntPtr SetWindowsHookEx(int id, LowLevelKeyboardProc proc, IntPtr hMod, uint threadId);
    [DllImport("user32.dll")] private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int vKey);
    [DllImport("kernel32.dll")] private static extern IntPtr GetModuleHandle(string? name);
}
