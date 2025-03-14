import 'package:flet/flet.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as wvw;
import 'dart:io';

class WebviewWindows extends StatefulWidget {
  final Control control;
  final FletControlBackend backend;
  final Color? bgcolor;

  const WebviewWindows({super.key, required this.control, required this.backend, this.bgcolor});

  @override
  State<WebviewWindows> createState() => _WebviewWindowsState();
}

class _WebviewWindowsState extends State<WebviewWindows> {
  late wvw.WebviewController controller;

  @override
  void initState() async {
    super.initState();
    controller = wvw.WebviewController();

    await controller.initialize();

    if (widget.bgcolor != null) {
      controller.setBackgroundColor(widget.bgcolor!);
    }

    await controller.loadUrl(widget.control.attrString("url", "https://flet.dev")!);

    controller.loadingState.listen((event) {
      if (event == wvw.LoadingState.loading) {
        controller.url.last.then((url) {
          debugPrint('WebViewControl page started loading: $url');
          widget.backend
              .triggerControlEvent(widget.control.id, "page_started", url);
        });
        debugPrint('WebViewControl is loading');
        widget.backend.triggerControlEvent(widget.control.id, "progress", "");
      } else if (event == wvw.LoadingState.navigationCompleted) {
        debugPrint('WebViewControl page finished loading');
        widget.backend.triggerControlEvent(widget.control.id, "page_ended", "");
      }
    }, onError: (error) {
      widget.backend.triggerControlEvent(widget.control.id,
          "web_resource_error", "WebView error: $error");
    });
    controller.url.listen((url) {
      debugPrint('WebViewControl URL changed: $url');
      widget.backend.triggerControlEvent(
          widget.control.id, "url_change", url ?? "");
    });

    controller.onLoadError.listen((event) {
      widget.backend.triggerControlEvent(widget.control.id,
          "web_resource_error", "WebView error: ${event.toString()}");
    });



    // Subscribe to backend methods
    widget.backend.subscribeMethods(widget.control.id,
            (methodName, args) async {
          switch (methodName) {
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
            //       (e.g. add canZoom flag to field and call setZoomFactor by eventListener)
            // case "enable_zoom":
            //   await controller.enableZoom(true);
            //   break;
            // case "disable_zoom":
            //   await controller.enableZoom(false);
            //   break;
            case "clear_cache":
              await controller.clearCache();
              break;
            // case "clear_local_storage":
            //   await controller.clearLocalStorage();
              break;
            case "get_current_url":
              return controller.url.last;
            case "get_title":
              return controller.title.last;
            // case "get_user_agent":
            //   return await controller.getUserAgent();
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
            // case "scroll_to":
            //   var x = parseInt(args["x"]);
            //   var y = parseInt(args["y"]);
            //   if (x != null && y != null) {
            //     await controller.scrollTo(x, y);
            //   }
            //   break;
            // case "scroll_by":
            //   var x = parseInt(args["x"]);
            //   var y = parseInt(args["y"]);
            //   if (x != null && y != null) {
            //     await controller.scrollBy(x, y);
            //   }
            //   break;
            // case "set_javascript_mode":
            //   var value = parseBool(args["value"]);
            //   if (value != null) {
            //     await controller.setJavaScriptMode(
            //         value ? JavaScriptMode.unrestricted : JavaScriptMode.disabled);
            //   }
              break;
          }
          return null;
        });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("WebViewControl build: ${widget.control.id}");

    return wvw.Webview(controller);
  }
}
