import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
 
import 'package:flutter/widgets.dart';


class MissingDataAlert extends StatefulWidget {
  const MissingDataAlert({Key? key}) : super(key: key);

  @override
  State<MissingDataAlert> createState() => _MissingDataAlertState();
}

class _MissingDataAlertState extends State<MissingDataAlert>{
  List<FileSystemEntity> _files = List.empty();
  String _dir = "";
 
  void getFiles() async { //asyn function to get list of files
      await getAllFiles();
      setState(() {}); //update the UI
  }

  @override
  void initState() {
    getFiles(); //call getFiles() function on initial state. 
    super.initState();
  }


Future<void> getAllFiles() async {
  final directory = await getApplicationDocumentsDirectory();
  _dir = directory.path;
  String pdfDirectory = '$_dir/vasis';
  final myDir = new Directory(pdfDirectory);
  setState(() {
    _files = myDir.listSync(recursive: true, followLinks: false);
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("vasisbeats application directory : $_dir"),
        backgroundColor: Colors.redAccent
      ),
      body:_files == null? Text("Searching Files"):
           ListView.builder(  //if file/folder list is grabbed, then show here
              itemCount: _files?.length ?? 0,
              itemBuilder: (context, index) {
                    return Card(
                      child:ListTile(
                         title: Text(_files[index].path.split('/').last),
                         leading: Icon(Icons.image),
                         trailing: Icon(Icons.delete, color: Colors.redAccent,),
                      )
                    );
              },
          )
    );
  }
}





