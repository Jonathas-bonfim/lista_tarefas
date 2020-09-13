import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

void main(){
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
    ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;


  @override
  void initState(){    //ajuda na leitura dos dados
    super.initState();

    _readData().then((data){
      setState(() {
         _toDoList = jsonDecode(data);
      });
    });
  }

  final _toDoController = TextEditingController();

  void _addToDo(){
    setState(() { //para atualizar a tela quando pressionar o botão
      Map<String, dynamic> newTodo = Map();
    newTodo["title"] = _toDoController.text;
    _toDoController.text = ""; //após clicar no botão vai deixar o campo vazio
    newTodo["ok"] = false; //iniciar a tarefa como não concluída
    _toDoList.add(newTodo); //adicionando a tarefa
    _saveData();
    });
  }
  
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b){ 
      /* Precisamos retornar 1 ou qualquer outro número positivo caso A seja maior que B,  
    temos que retornar 0 caso sejam iguais e retornar números negativos caso B seja maior que A*/
      if(a["ok"] && !b["ok"]) return 1;
      else if(!a["ok"] && b["ok"]) return -1; 
      else return 0;
    });

    _saveData();
    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
       title: Text("Lista de Tarefas"),
       backgroundColor: Colors.blueAccent,
       centerTitle: true,
       actions: <Widget>[
        IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: (){
              setState(() {
              //print("A quantidade de itens é: ${_toDoList.length}");
              _toDoList.removeRange(0, _toDoList.length); //remover todos os itens
              _saveData();
              });
            },
            
          )
        ]
     ), 
     body: Column(
       children: <Widget>[
         Container(
           padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
           child: Row(
             children: <Widget>[
               Expanded(
                 child: TextField(
                  controller: _toDoController,
                  decoration: InputDecoration(
                  labelText: "Nova tarefa",
                  labelStyle: TextStyle(color: Colors.blueAccent)
                ),
              ),
                 ),
              RaisedButton(
                color: Colors.blueAccent,
                child: Text("ADD"),
                textColor: Colors.white,
                onPressed: _addToDo,
              ) 
             ],
           ),
         ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, 
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _toDoList.length,
              itemBuilder: buildItem),
              ),
          )
       ],
     ),
    );
  }

  Widget buildItem(BuildContext context, int index){
                return Dismissible( //função para deletar
                  key: Key(DateTime.now().millisecondsSinceEpoch.toString()), //para identificar o arquivo removido
                  background: Container(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment(-0.9, 0.0), //para alinhar o ícone para a esquerda
                      child: Icon(Icons.delete, 
                              color: Colors.white,),
                  ),
                  ),
                  direction: DismissDirection.startToEnd,  //deletar arrastando para direita
                  child: CheckboxListTile(
                  title: Text(_toDoList[index]["title"]),
                  value: _toDoList[index]["ok"],
                  secondary: CircleAvatar(
                    child: Icon(_toDoList[index]["ok"] ?
                    Icons.check : Icons.error),),
                  onChanged: (c){
                    setState(() {
                      _toDoList[index]["ok"] = c;
                      _saveData();
                    });
                  },
                ),
                onDismissed: (direcao){
                  setState(() {
                   _lastRemoved = Map.from(_toDoList[index]); //duplicar a linha que foi deletada
                   _lastRemovedPos = index; //pegando a posição para voltar para o mesmo lugar
                   _toDoList.removeAt(index);
                   
                  
                   _saveData();

                   final snack = SnackBar( //para desfazer a ação de excluir
                     content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"), //mostrar o nome da tarefa removida
                     action: SnackBarAction(label: "Desfazer", 
                     onPressed: (){ //restaurando o item
                        setState(() {
                         _toDoList.insert(_lastRemovedPos, _lastRemoved);
                        _saveData(); 
                        });
                     }),
                     duration: Duration(seconds: 2),
                     );
                     Scaffold.of(context).removeCurrentSnackBar(); 
                     Scaffold.of(context).showSnackBar(snack); //para mostrar o snackbar

                  });
                  
                },
                );
              }

   /* */          

  Future<File> _getFile() async{
  final directory = await getApplicationDocumentsDirectory();
  return File("${directory.path}/data.json");
}

Future<File> _saveData() async{
  String data = json.encode(_toDoList); //pegando a lista, transformando em um json e salvando em uma string
  final file = await _getFile();
  return file.writeAsString(data);

}

Future<String> _readData() async{
  try {
    final file = await _getFile();

    return file.readAsStringSync();
    
  } catch (e) {
    return null;
  }
}

}

