import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/categories_contents_list.dart';
import 'package:app_movie/pages/search.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
  }

  renderCategories() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 800 ? 3 : 6,
          ),
          itemCount: Config.genres.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CategoriesContentsList(
                              name: Config.genres[index]["name"].toString(),
                              movie: int.parse(
                                  Config.genres[index]["movie"].toString()),
                              serie: int.parse(
                                  Config.genres[index]["serie"].toString()))));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  height: 30,
                  width: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(64),
                            child: Container(
                                height: 56,
                                width: 56,
                                color: Config.secondaryColor,
                                child: Image.asset(
                                    Config.genres[index]["icon"].toString())),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            Config.genres[index]["name"].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )
                        ]),
                  ),
                ),
              ),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Categorias"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (contexxt) => const SearchPage()));
              },
              icon: const Icon(Icons.search)),
        ],
      ),
      body: renderCategories(),
      bottomNavigationBar: const Footer(current: 3),
    );
  }
}
