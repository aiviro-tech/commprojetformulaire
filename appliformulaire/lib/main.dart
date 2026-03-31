import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:appliformulaire/services/api_service.dart';

void main() {
  runApp(
    const MaterialApp(home: Connexion(), debugShowCheckedModeBanner: false),
  );
}

// ==========================================
// 1. PAGE DE CONNEXION
// ==========================================
class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Connexion réussie !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Connexion", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                InputCustom(label: "Email", hint: "votre-email@gmail.com", isEmail: true, controller: _emailController),
                const SizedBox(height: 15),
                InputCustom(label: "Mot de passe", hint: "Saisir votre mot de passe", isPassword: true, controller: _passwordController),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage())),
                    child: const Text("Mot de passe oublié ?", style: TextStyle(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    text: "Pas de compte ? ",
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Inscrivez-vous",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Inscription())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. RÉCUPÉRATION : ÉTAPE 1 (EMAIL)
// ==========================================
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ApiService.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code envoyé par email !'), backgroundColor: Colors.green),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpResetPage(email: _emailController.text.trim())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Récupération")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Réinitialisation", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              InputCustom(label: "Email", hint: "votre-email@gmail.com", isEmail: true, controller: _emailController),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Envoyer le code"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. RÉCUPÉRATION : ÉTAPE 2 (CODE OTP)
// ==========================================
class OtpResetPage extends StatefulWidget {
  final String email;
  const OtpResetPage({super.key, required this.email});

  @override
  State<OtpResetPage> createState() => _OtpResetPageState();
}

class _OtpResetPageState extends State<OtpResetPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  String _errorMessage = "";
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var c in _controllers) {
      c.addListener(() => setState(() => _isButtonEnabled = _controllers.every((c) => c.text.length == 1)));
    }
  }

  Future<void> _verifyOtp() async {
    String codeSaisi = _controllers.map((e) => e.text).join();
    setState(() => _isLoading = true);
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewPasswordPage(email: widget.email, otpCode: codeSaisi)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Vérification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Entrez le code à 6 chiffres reçu par email.", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(6, (index) => _otpBox(index))),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) ...[
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  setState(() => _errorMessage = "");
                  for (var c in _controllers) { c.clear(); }
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
              ),
            ],
            const SizedBox(height: 30),
            if (_errorMessage.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isButtonEnabled && !_isLoading) ? _verifyOtp : null,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Valider le code"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) => SizedBox(
    width: 45,
    child: TextField(
      controller: _controllers[index],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      onChanged: (v) {
        if (v.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
        if (v.isEmpty && index > 0) FocusScope.of(context).previousFocus();
      },
      decoration: const InputDecoration(counterText: "", border: OutlineInputBorder()),
    ),
  );
}

// ==========================================
// 4. RÉCUPÉRATION : ÉTAPE 3 (NOUVEAU PASS)
// ==========================================
class NewPasswordPage extends StatefulWidget {
  final String email;
  final String otpCode;
  const NewPasswordPage({super.key, required this.email, required this.otpCode});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: widget.email,
        otpCode: widget.otpCode,
        password: _passController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mot de passe mis à jour !"), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Connexion()), (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouveau mot de passe")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Réinitialisation", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              InputCustom(label: "Nouveau mot de passe", hint: "Saisir le nouveau mot de passe", isPassword: true, controller: _passController),
              const SizedBox(height: 15),
              InputCustom(
                label: "Confirmer",
                hint: "Confirmer le mot de passe",
                isPassword: true,
                controller: _confirmPassController,
                validator: (v) => v != _passController.text ? "Les mots de passe ne correspondent pas" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Enregistrer"),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Connexion()), (route) => false),
                child: const Text("Ignorer", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. PAGE D'INSCRIPTION
// ==========================================
class Inscription extends StatefulWidget {
  const Inscription({super.key});
  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inscription réussie ! Code OTP envoyé."), backgroundColor: Colors.green),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ValidationInscription(email: _emailController.text.trim())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Inscription", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              InputCustom(label: "Nom", hint: "Votre nom", controller: _lastNameController),
              const SizedBox(height: 15),
              InputCustom(label: "Prénom", hint: "Votre prénom", controller: _firstNameController),
              const SizedBox(height: 15),
              InputCustom(label: "Email", hint: "votre-nom@gmail.com", isEmail: true, controller: _emailController),
              const SizedBox(height: 15),
              InputCustom(label: "Mot de passe", hint: "Mot de passe", isPassword: true, controller: _passController),
              const SizedBox(height: 15),
              InputCustom(
                label: "Confirmer",
                hint: "Confirmer le mot de passe",
                isPassword: true,
                controller: _confirmPassController,
                validator: (value) => value != _passController.text ? "mot de passe incorrect" : null,
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) => setState(() => _acceptTerms = v!),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "J'accepte les politiques de ",
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          TextSpan(
                            text: "sécurités",
                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PolicyPage(
                                      title: "Politiques de Sécurité",
                                      content: """
POLITIQUE DE SÉCURITÉ DES SYSTÈMES

1. PROTECTION DES ACCÈS
L'accès à votre compte est protégé par un système de hachage cryptographique de pointe. Nous ne stockons jamais votre mot de passe en texte clair. Chaque tentative de connexion est surveillée pour détecter d'éventuelles activités suspectes ou des attaques par force brute.

2. CHIFFREMENT DES DONNÉES
Toutes les données échangées entre votre appareil et nos serveurs sont cryptées via le protocole TLS (Transport Layer Security) 1.3. Les données stockées sur nos serveurs sont également protégées par un chiffrement AES-256 bits au repos.

3. INFRASTRUCTURE ET RÉSEAU
Notre infrastructure est hébergée dans des datacenters hautement sécurisés, certifiés ISO 27001 et SOC 2. Nous utilisons des pare-feu applicatifs (WAF) et des systèmes de détection d'intrusion pour bloquer les menaces en temps réel.

4. AUDITS ET MISES À JOUR
Nous effectuons des tests d'intrusion réguliers et des scans de vulnérabilité. Les correctifs de sécurité sont appliqués immédiatement après leur sortie pour garantir que l'application est toujours protégée contre les dernières menaces connues.

5. RESPONSABILITÉ DE L'UTILISATEUR
La sécurité est une responsabilité partagée. Nous vous encourageons à utiliser un mot de passe complexe et unique, et à ne jamais partager vos identifiants de connexion avec des tiers.
                                """,
                                    ),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: " et "),
                          TextSpan(
                            text: "confidentialités",
                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PolicyPage(
                                      title: "Confidentialité",
                                      content: """
DÉCLARATION DE CONFIDENTIALITÉ ET RGPD

1. COLLECTE DES INFORMATIONS
Nous collectons uniquement les données strictement nécessaires au fonctionnement de l'application : nom, prénom, adresse e-mail et journaux techniques de connexion. Ces informations nous permettent de personnaliser votre expérience et d'assurer le support technique.

2. UTILISATION DES DONNÉES
Vos données sont traitées uniquement pour les finalités suivantes :
- Gestion de votre profil utilisateur.
- Envoi de notifications liées à la sécurité du compte.
- Analyse anonymisée pour l'amélioration de nos services.

3. PARTAGE DES DONNÉES
Nous nous engageons formellement à ne jamais vendre, louer ou céder vos données personnelles à des tiers à des fins marketing ou publicitaires. Le partage de données n'intervient que si la loi l'exige ou pour le traitement de services tiers indispensables (ex: envoi d'emails).

4. DURÉE DE CONSERVATION
Vos données personnelles sont conservées tant que votre compte reste actif. En cas de demande de suppression ou d'inactivité prolongée (supérieure à 3 ans), vos informations sont définitivement effacées de nos serveurs sous 30 jours.

5. VOS DROITS (RGPD)
Conformément à la réglementation, vous disposez d'un droit d'accès, de rectification, de portabilité et d'effacement de vos données. Pour exercer ces droits, vous pouvez nous contacter via la section support de l'application.

6. COOKIES ET TRACEURS
Nous utilisons uniquement des traceurs techniques essentiels à la navigation et à l'authentification. Aucun traceur publicitaire n'est implanté dans cette application sans votre accord préalable.
                                """,
                                    ),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: " de l'utilisation de l'application"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('S\'inscrire'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. VALIDATION INSCRIPTION
// ==========================================
class ValidationInscription extends StatefulWidget {
  final String email;
  const ValidationInscription({super.key, required this.email});

  @override
  State<ValidationInscription> createState() => _ValidationInscriptionState();
}

class _ValidationInscriptionState extends State<ValidationInscription> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  bool _isButtonEnabled = false;
  String _errorMessage = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var c in _otpControllers) {
      c.addListener(() => setState(() => _isButtonEnabled = _otpControllers.every((c) => c.text.length == 1)));
    }
  }

  Future<void> _finaliserInscription() async {
    String codeSaisi = _otpControllers.map((e) => e.text).join();
    setState(() => _isLoading = true);
    try {
      await ApiService.verifyEmail(email: widget.email, code: codeSaisi);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte validé avec succès !"), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Connexion()), (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Validation")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Veuillez entrer le code envoyé par email", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 40,
                  child: TextField(
                    controller: _otpControllers[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (v) {
                      if (v.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
                      if (v.isEmpty && index > 0) FocusScope.of(context).previousFocus();
                    },
                    decoration: const InputDecoration(counterText: "", border: OutlineInputBorder()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty) ...[
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  setState(() => _errorMessage = "");
                  for (var c in _otpControllers) {
                    c.clear();
                  }
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
              ),
            ],
            const SizedBox(height: 30),
            if (_errorMessage.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: (_isButtonEnabled && !_isLoading) ? _finaliserInscription : null,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Valider"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. WIDGETS DE BASE
// ==========================================
class PolicyPage extends StatelessWidget {
  final String title;
  final String content;
  const PolicyPage({super.key, required this.title, required this.content});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(25), child: Text(content, textAlign: TextAlign.justify)),
    );
  }
}

class InputCustom extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final bool isEmail;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  const InputCustom({super.key, required this.label, required this.hint, this.isPassword = false, this.isEmail = false, this.controller, this.validator});
  @override
  State<InputCustom> createState() => _InputCustomState();
}

class _InputCustomState extends State<InputCustom> {
  late bool _obscure;
  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.isEmail ? TextInputType.emailAddress : TextInputType.text,
          validator: widget.validator ??
              (value) {
                if (value == null || value.isEmpty) return "Champ obligatoire";
                if (widget.isEmail) {
                  final bool gmailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@gmail\.com$").hasMatch(value);
                  if (!gmailValid) return "gmail incorrect";
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: widget.isPassword ? IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}