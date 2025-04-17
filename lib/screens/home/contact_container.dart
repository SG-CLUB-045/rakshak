import 'package:flutter/material.dart';

class ContactWidget extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final int index;
  final void Function(int) onDelete;

  const ContactWidget(
      {super.key,
      required this.name,
      required this.phone,
      required this.email,
      required this.onDelete,
      required this.index});

  @override
  Widget build(BuildContext context) {
    final List<Color> colorPalette = [
      Colors.purple.shade100,
      Colors.yellow.shade100,
      Colors.green.shade100,
    ];
    Color randomColor = colorPalette[index%colorPalette.length];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [randomColor, Colors.pink.shade400]),
        borderRadius: BorderRadius.circular(12),
        color: Colors.pink.shade200,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.pink.shade400,
            ),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              Text(
                phone,
                style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
              Text(
                email,
                style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => onDelete(index),
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
