List<FocusNode> focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  final List<TextEditingController> textFields = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

    Material(
                child: Row(
                  spacing: 10,
                  children: [
                    ...List.generate(
                      6,
                      (index) => Expanded(
                        child: TextField(
                          maxLength: 2,
                          focusNode: focusNodes[index],
                          controller: textFields[index],
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            counter: const SizedBox(),
                          ),
                          onChanged: (value) {
                            if (value.contains(' ') && index > 0) {
                              textFields[index].text = value.trim();
                            }
                            if (value.trim().length > 1 && index < 5) {
                              textFields[index].text =
                                  value.trim().substring(0, 1);
                              textFields[index + 1].text =
                                  value.trim().substring(1);
                              focusNodes[index + 1].requestFocus();
                            } else if (value.trim().isEmpty && index > 0) {
                              focusNodes[index - 1].requestFocus();
                            } else if (value.trim().isNotEmpty && index < 5) {
                              textFields[index + 1].text = " ";
                              focusNodes[index + 1].requestFocus();
                            }
                            if (value.trim().length > 1 && index == 5) {
                              textFields[index].text = value.trim().substring(0, 1);
                            }
                            textFields[index].text = textFields[index].value.text.toUpperCase();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),