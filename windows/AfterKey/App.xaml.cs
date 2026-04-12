using System.Drawing;
using System.Windows;
using Forms = System.Windows.Forms;

namespace AfterKey;

public partial class App : Application
{
    private OverlayWindow _overlay = null!;
    private KeyboardHook _hook = null!;
    private Forms.NotifyIcon _tray = null!;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        _overlay = new OverlayWindow();
        _overlay.Show();

        _hook = new KeyboardHook();
        _hook.KeyPressed += _overlay.AddKey;
        _hook.Start();

        SetupTray();
    }

    private void SetupTray()
    {
        _tray = new Forms.NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "AfterKey",
            Visible = true,
            ContextMenuStrip = new Forms.ContextMenuStrip()
        };

        _tray.ContextMenuStrip.Items.Add("Settings...", null, (_, _) => OpenSettings());
        _tray.ContextMenuStrip.Items.Add("-");
        _tray.ContextMenuStrip.Items.Add("Quit", null, (_, _) => Shutdown());
    }

    private void OpenSettings()
    {
        var win = new SettingsWindow { Owner = null };
        win.Show();
        win.Activate();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _hook.Dispose();
        _tray.Visible = false;
        _tray.Dispose();
        base.OnExit(e);
    }
}
