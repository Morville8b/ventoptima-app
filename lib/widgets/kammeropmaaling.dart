import 'package:flutter/material.dart';

Future<KammerData?> visKammerOpmalingPopup(BuildContext context) async {
  const Color matchingGreen = Color(0xFF34E0A1);
  const Color matchingBlue = Color(0xFF006390);

  final TextEditingController breddeController = TextEditingController();
  final TextEditingController hoejdeController = TextEditingController();
  final TextEditingController laengdeController = TextEditingController();

  return await Navigator.of(context).push<KammerData>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1), // Start over skærmen
            end: Offset.zero, // Slut på normal position
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: matchingGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.straighten,
                        size: 40,
                        color: matchingBlue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Mål opstillingskammer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: matchingBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'Indtast mål på det kammer, hvor ventilatorerne skal monteres:',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Image
                    Image.asset(
                      'assets/images/opmaaling_af_ventilatorkammer.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),

                    // Input fields
                    TextField(
                      controller: breddeController,
                      keyboardType: TextInputType.text,
                      autofocus: false,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: 'Bredde (mm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.width_full, color: matchingGreen),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: hoejdeController,
                      keyboardType: TextInputType.text,
                      autofocus: false,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: 'Højde (mm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.height, color: matchingGreen),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: laengdeController,
                      keyboardType: TextInputType.text,
                      autofocus: false,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: 'Længde (mm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.straighten, color: matchingGreen),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: matchingGreen, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Annuller',
                              style: TextStyle(
                                color: matchingBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final double? bredde = double.tryParse(breddeController.text.replaceAll(',', '.'));
                              final double? hoejde = double.tryParse(hoejdeController.text.replaceAll(',', '.'));
                              final double? laengde = double.tryParse(laengdeController.text.replaceAll(',', '.'));

                              if (bredde != null && hoejde != null && laengde != null) {
                                Navigator.pop(context, KammerData(
                                  bredde: bredde,
                                  hoejde: hoejde,
                                  laengde: laengde,
                                ));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: matchingGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Gem',
                              style: TextStyle(
                                color: matchingBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}

class KammerData {
  final double bredde;
  final double hoejde;
  final double laengde;

  KammerData({required this.bredde, required this.hoejde, required this.laengde});
}
