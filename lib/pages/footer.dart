import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/home_page.dart';
import 'package:app_movie/pages/categories.dart';
import 'package:app_movie/pages/configuration.dart';
import 'package:app_movie/pages/favorites.dart';
import 'package:app_movie/pages/triggers.dart';
import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  final int current;
  const Footer({super.key, this.current = 1});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final double _size = 25;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          height: _size + 37,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 2.0,
                  color: widget.current == 1
                      ? (Config.primaryColor)!
                      : Colors.transparent),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Config.primaryColor,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.home,
                    size: _size,
                    color: widget.current == 1
                        ? Config.primaryColor
                        : Colors.grey[700],
                  ),
                  Text(
                    "Home",
                    style: TextStyle(
                        color: widget.current == 1
                            ? Config.primaryColor
                            : Colors.grey[700],
                        fontSize: 10),
                  )
                ],
              ),
              onPressed: () {
                if (widget.current != 1) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (Route<dynamic> route) => false);
                }
              },
            ),
          ),
        ),
        Container(
          height: _size + 37,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 2.0,
                  color: widget.current == 2
                      ? (Config.primaryColor)!
                      : Colors.transparent),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Config.primaryColor,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: _size,
                    color: widget.current == 2
                        ? Config.primaryColor
                        : Colors.grey[700],
                  ),
                  Text(
                    "Gatilhos",
                    style: TextStyle(
                        color: widget.current == 2
                            ? Config.primaryColor
                            : Colors.grey[700],
                        fontSize: 10),
                  )
                ],
              ),
              onPressed: () {
                if (widget.current != 2) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (contenxt) => const Triggers(
                                triggers: [],
                              )));
                }
              },
            ),
          ),
        ),
        Container(
          height: _size + 37,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 2.0,
                  color: widget.current == 3
                      ? (Config.primaryColor)!
                      : Colors.transparent),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Config.primaryColor,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.line_style_sharp,
                    size: _size,
                    color: widget.current == 3
                        ? Config.primaryColor
                        : Colors.grey[700],
                  ),
                  Text(
                    "Categorias",
                    style: TextStyle(
                        color: widget.current == 3
                            ? Config.primaryColor
                            : Colors.grey[700],
                        fontSize: 10),
                  )
                ],
              ),
              onPressed: () {
                if (widget.current != 3) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (contenxt) => const CategoriesPage()));
                }
              },
            ),
          ),
        ),
        Container(
          height: _size + 37,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 2.0,
                  color: widget.current == 4
                      ? (Config.primaryColor)!
                      : Colors.transparent),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Config.primaryColor,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    size: _size,
                    color: widget.current == 4
                        ? Config.primaryColor
                        : Colors.grey[700],
                  ),
                  Text(
                    "Favoritos",
                    style: TextStyle(
                        color: widget.current == 4
                            ? Config.primaryColor
                            : Colors.grey[700],
                        fontSize: 10),
                  )
                ],
              ),
              onPressed: () {
                if (widget.current != 4) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (contenxt) => const Favorites()));
                }
              },
            ),
          ),
        ),
        Container(
          height: _size + 37,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 2.0,
                  color: widget.current == 5
                      ? (Config.primaryColor)!
                      : Colors.transparent),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Config.primaryColor,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.menu,
                    size: _size,
                    color: widget.current == 5
                        ? Config.primaryColor
                        : Colors.grey[700],
                  ),
                  Text(
                    "Configurações",
                    style: TextStyle(
                        color: widget.current == 5
                            ? Config.primaryColor
                            : Colors.grey[700],
                        fontSize: 9),
                  )
                ],
              ),
              onPressed: () {
                if (widget.current != 5) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (contenxt) => const ConfigurationPage()));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
