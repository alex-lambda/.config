// Hides SketchyBar while the real macOS menu bar is visible.
//
// The Window Server keeps its native menu bar window in the window list while
// it animates on and off screen. Observing that window means we follow the
// menu bar's actual state rather than guessing it from the cursor position.
// This uses public CoreGraphics APIs and requires no Accessibility permission.
//
// Usage: menubar_watch

#include <CoreGraphics/CoreGraphics.h>
#include <signal.h>
#include <stdbool.h>
#include <sys/wait.h>
#include <unistd.h>

#define POLL_INTERVAL_US 30000

static volatile sig_atomic_t g_stop = 0;

static void on_signal(int signum) {
  (void)signum;
  g_stop = 1;
}

static void set_bar_hidden(bool hidden) {
  pid_t pid = fork();
  if (pid == 0) {
    execlp("sketchybar", "sketchybar",
           "--bar", hidden ? "hidden=on" : "hidden=off", (char *)NULL);
    _exit(127);
  }
  if (pid > 0) waitpid(pid, NULL, 0);
}

static bool dictionary_string_equals(CFDictionaryRef dictionary,
                                     const void *key,
                                     CFStringRef expected) {
  CFTypeRef value = CFDictionaryGetValue(dictionary, key);
  return value && CFGetTypeID(value) == CFStringGetTypeID()
      && CFStringCompare((CFStringRef)value, expected, 0) == kCFCompareEqualTo;
}

static bool native_menu_bar_visible(void) {
  CFArrayRef windows = CGWindowListCopyWindowInfo(kCGWindowListOptionAll,
                                                   kCGNullWindowID);
  if (!windows) return false;

  bool visible = false;
  CFIndex count = CFArrayGetCount(windows);
  for (CFIndex i = 0; i < count; ++i) {
    CFTypeRef value = CFArrayGetValueAtIndex(windows, i);
    if (!value || CFGetTypeID(value) != CFDictionaryGetTypeID()) continue;

    CFDictionaryRef window = (CFDictionaryRef)value;
    if (!dictionary_string_equals(window, kCGWindowOwnerName,
                                  CFSTR("Window Server"))
        || !dictionary_string_equals(window, kCGWindowName,
                                     CFSTR("Menubar"))) {
      continue;
    }

    CFTypeRef onscreen = CFDictionaryGetValue(window, kCGWindowIsOnscreen);
    if (onscreen && CFGetTypeID(onscreen) == CFBooleanGetTypeID()
        && CFBooleanGetValue((CFBooleanRef)onscreen)) {
      visible = true;
      break;
    }
  }

  CFRelease(windows);
  return visible;
}

int main(void) {
  signal(SIGINT, on_signal);
  signal(SIGTERM, on_signal);

  bool hidden = native_menu_bar_visible();
  set_bar_hidden(hidden);

  while (!g_stop) {
    bool should_hide = native_menu_bar_visible();
    if (hidden != should_hide) {
      hidden = should_hide;
      set_bar_hidden(hidden);
    }

    usleep(POLL_INTERVAL_US);
  }

  // Never leave the bar hidden on exit or reload.
  set_bar_hidden(false);
  return 0;
}
