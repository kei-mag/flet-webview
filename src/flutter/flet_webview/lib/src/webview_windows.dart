import 'package:flet/flet.dart';
import 'package:flet_webview/src/utils/webview.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as webview_windows;

class WebviewWindows extends StatefulWidget {
  final Control control;

  const WebviewWindows({super.key, required this.control});

  @override
  State<WebviewWindows> createState() => _WebviewWindowsState();
}

class _WebviewWindowsState extends State<WebviewWindows> {
  late webview_windows.WebviewController controller;

  @override
  void initState() async {
    super.initState();
    widget.control.addInvokeMethodListener(_invokeMethod);

    controller = webview_windows.WebviewController();
    await controller.initialize();

    controller.loadingState.listen((event) {
      if (event == webview_windows.LoadingState.loading) {
        controller.url.last.then((url) {
          widget.control.triggerEvent("page_started", url);
        });
      } else if (event == webview_windows.LoadingState.navigationCompleted) {
        controller.url.last.then((url) {
          widget.control.triggerEvent("page_ended", url);
        });
      }
    }, onError: (error) {
      widget.control.triggerEvent("web_resource_error", "WebView error: $error");
    });
    controller.url.listen((url) {
      debugPrint('WebViewControl URL changed: $url');
      widget.control.triggerEvent("url_change", url);
    });

    controller.onLoadError.listen((event) {
      widget.control.triggerEvent(
          "web_resource_error", "WebView error: ${event.toString()}");
    });

    // request
    // NOTE: args["method"] is not supported.
    controller.loadUrl(widget.control.getString("url", "https://flet.dev")!);
  }


  Future<dynamic> _invokeMethod(String name, dynamic args) async {
    debugPrint("WebView.$name($args)");
    switch (name) {
      case "reload":
        await controller.reload();
        break;
      case "can_go_back":
        return (await controller.historyChanged.last).canGoBack.toString();
      case "can_go_forward":
        return (await controller.historyChanged.last).canGoForward.toString();
      case "go_back":
        if ((await controller.historyChanged.last).canGoBack) {
          await controller.goBack();
        }
        break;
      case "go_forward":
        if ((await controller.historyChanged.last).canGoForward) {
          await controller.goForward();
        }
        break;
      // NOTE: controller.enableZoom is not supported in webview_windows
      //       but zooming is supported by controller.setZoomFactor.
      //       Maybe similar functionality can be implemented by manually
      //       (e.g. add canZoom flag to field and call setZoomFactor by eventListener).
      case "enable_zoom":
        throw noSuchMethod(Invocation.method(const Symbol("enable_zoom"), null));
      case "disable_zoom":
        throw noSuchMethod(Invocation.method(const Symbol("disable_zoom"), null));
      case "clear_cache":
        await controller.clearCache();
        break;
      case "clear_local_storage":
        // NOTE: Not supported in webview_windows.
        throw noSuchMethod(Invocation.method(const Symbol("clear_local_storage"), null));
      case "get_current_url":
        return await controller.url.last;
      case "get_title":
        return await controller.title.last;
      case "get_user_agent":
        // NOTE: Not supported in webview_windows.
        throw noSuchMethod(Invocation.method(const Symbol("get_user_agent"), null));
      case "load_file":
        var path = args["path"];
        if (path != null) {
          final File file = File(path);
          String html = file.readAsStringSync();
          await controller.loadStringContent(html);
        }
        break;
      case "load_html":
        var html = args["value"];
        if (html != null) {
          await controller.loadStringContent(html);
        }
        break;
      case "load_request":
        var url = args["url"];
        if (url != null) {
          await controller.loadUrl(url); // NOTE: args["method"] is not supported.
        }
        break;
      case "run_javascript":
        var javascript = args["value"];
        if (javascript != null) {
          await controller.executeScript(javascript);
        }
        break;
      case "scroll_to":
        var x = parseInt(args["x"]);
        var y = parseInt(args["y"]);
        if (x != null && y != null) {
          // NOTE: Not supported in webview_windows.
          throw noSuchMethod(Invocation.method(const Symbol("scroll_to"), [x, y]));
        }
        break;
      case "scroll_by":
        var x = parseInt(args["x"]);
        var y = parseInt(args["y"]);
        if (x != null && y != null) {
          // NOTE: Not supported in webview_windows.
          throw noSuchMethod(Invocation.method(const Symbol("scroll_by"), [x, y]));
        }
        break;
      case "set_javascript_mode":
        var mode = parseJavaScriptMode(args["mode"]);
        if (mode != null) {
          // NOTE: Not supported in webview_windows.
          throw noSuchMethod(Invocation.method(const Symbol("set_javascript_mode"), [mode]));
        }
        break;
      default:
        throw Exception("Unknown WebView method: $name");
    }
  }

  @override
  void dispose() {
    debugPrint("WebViewControl dispose: ${widget.control.id}");
    widget.control.removeInvokeMethodListener(_invokeMethod);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("WebViewControl build: ${widget.control.id}");

    var bgcolor = widget.control.getColor("bgcolor", context);

    if (bgcolor != null) {
      controller.setBackgroundColor(bgcolor);
    }

    return webview_windows.Webview(controller);
  }
}