import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart' as stat;

class PreviewServer {
  final String rootDirectory;

  PreviewServer(this.rootDirectory);

  Future<void> start() async {
    final handler = shelf.Cascade()
        .add(stat.createStaticHandler(rootDirectory,
          defaultDocument: 'index.html',
          listDirectories: true,
        ))
        .handler;

    final server = await io.serve(handler, 'localhost', 8080);
    print('Serving at http://${server.address.host}:${server.port}');
  }
}
