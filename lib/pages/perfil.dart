import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/user.dart';
import 'package:app_movie/pages/edit_user.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  User? user;
  bool _isLoaded = false;
  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  fetchUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userPrefs = prefs.getStringList("user");

    var userDb = await db
        .collection("users")
        .where("email", isEqualTo: userPrefs![Config.id])
        .get();

    var userData = userDb.docs.first.data();
    userData["id"] = userDb.docs.first.id;
    setState(() {
      user = User.fromJson(userData);
      _isLoaded = true;
    });
  }

  renderUser() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Container(
                  alignment: Alignment.center,
                  color: Config.panelColor2,
                  height: 100,
                  width: 100,
                  child: user!.image == ''
                      ? const Icon(
                          Icons.person,
                          size: 64,
                        )
                      : Image.network(user!.image)),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "@${user!.username}",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(
            height: 16,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nome",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(user!.name + " " + user!.lastName),
              const SizedBox(
                height: 12,
              ),
              Divider(
                color: Colors.grey[350],
              ),
              const Text(
                "Username",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(user!.username),
              const SizedBox(
                height: 12,
              ),
              Divider(
                color: Colors.grey[350],
              ),
              const Text(
                "Email",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(user!.email),
              const SizedBox(
                height: 12,
              ),
              Divider(
                color: Colors.grey[350],
              ),
              const Text(
                "Telefone",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(""),
              const SizedBox(
                height: 12,
              ),
              Divider(
                color: Colors.grey[350],
              )
            ],
          ),
          const SizedBox(
            height: 32,
          ),
          SizedBox(
            width: 160,
            child: ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Config.btnColor),
                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)))),
                ),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) => const EditUser()))
                      .then((value) {
                    if (value != null && value) {
                      fetchUser();
                    }
                  });
                },
                child: const Text(
                  "Editar",
                  style: TextStyle(color: Colors.white),
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            child: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: Colors.white,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          automaticallyImplyLeading: false,
          title: const Text("Perfil"),
        ),
        body: _isLoaded
            ? renderUser()
            : Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(color: Config.primaryColor),
                ),
              ),
        bottomNavigationBar: const Footer(
          current: 5,
        ));
  }
}
