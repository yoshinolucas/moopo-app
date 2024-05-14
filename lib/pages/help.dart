import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: InkWell(
            child: const Icon(
              Icons.arrow_back_ios,
              size: 18,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Ajuda')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(
              height: 24,
            ),
            const Text(
              'Tem alguma dúvida ou quer reportar um bug? Converse com a gente.',
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'moopo.aplicativo@gmail.com',
              textAlign: TextAlign.left,
              style: TextStyle(
                  color: Config.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            )
          ]),
        ),
      ),
      bottomNavigationBar: const Footer(
        current: 5,
      ),
    );
  }
}
