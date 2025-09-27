import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  // This list must eventually match the training data perfectly.
  final List<String> masterSymptomList = [
    'itching', 'skin_rash', 'nodal_skin_eruptions', 'continuous_sneezing', 'shivering', 'chills', 'joint_pain',
    'stomach_pain', 'acidity', 'ulcers_on_tongue', 'muscle_wasting', 'vomiting', 'burning_micturition', 'spotting_urination',
    'fatigue', 'weight_gain', 'anxiety', 'cold_hands_and_feets', 'mood_swings', 'weight_loss', 'restlessness', 'lethargy',
    'patches_in_throat', 'irregular_sugar_level', 'cough', 'high_fever', 'sunken_eyes', 'breathlessness', 'sweating',
    'dehydration', 'indigestion', 'headache', 'yellowish_skin', 'dark_urine', 'nausea', 'loss_of_appetite', 'pain_behind_the_eyes',
    'back_pain', 'constipation', 'abdominal_pain', 'diarrhoea', 'mild_fever', 'yellow_urine', 'yellowing_of_eyes',
    'acute_liver_failure', 'fluid_overload', 'swelling_of_stomach', 'swelled_lymph_nodes', 'malaise', 'blurred_and_distorted_vision',
    'phlegm', 'throat_irritation', 'redness_of_eyes', 'sinus_pressure', 'runny_nose', 'congestion', 'chest_pain', 'weakness_in_limbs',
    'fast_heart_rate', 'pain_during_bowel_movements', 'pain_in_anal_region', 'bloody_stool', 'irritation_in_anus', 'neck_pain',
    'dizziness', 'cramps', 'bruising', 'obesity', 'swollen_legs', 'swollen_blood_vessels', 'puffy_face_and_eyes',
    'enlarged_thyroid', 'brittle_nails', 'swollen_extremeties', 'excessive_hunger', 'extra_marital_contacts', 'drying_and_tingling_lips',
    'slurred_speech', 'knee_pain', 'hip_joint_pain', 'muscle_weakness', 'stiff_neck', 'swelling_joints', 'movement_stiffness',
    'spinning_movements', 'loss_of_balance', 'unsteadiness', 'weakness_of_one_body_side', 'loss_of_smell', 'bladder_discomfort',
    'foul_smell_of_urine', 'continuous_feel_of_urine', 'passage_of_gases', 'internal_itching', 'toxic_look_(typhos)',
    'depression', 'irritability', 'muscle_pain', 'altered_sensorium', 'red_spots_over_body', 'belly_pain',
    'abnormal_menstruation', 'dischromic_patches', 'watering_from_eyes', 'increased_appetite', 'polyuria', 'family_history',
    'mucoid_sputum', 'rusty_sputum', 'lack_of_concentration', 'visual_disturbances', 'receiving_blood_transfusion',
    'receiving_unsterile_injections', 'coma', 'stomach_bleeding', 'distention_of_abdomen', 'history_of_alcohol_consumption',
    'fluid_overload.1', 'blood_in_sputum', 'prominent_veins_on_calf', 'palpitations', 'painful_walking', 'pus_filled_pimples',
    'blackheads', 'scurring', 'skin_peeling', 'silver_like_dusting', 'small_dents_in_nails', 'inflammatory_nails',
    'blister', 'red_sore_around_nose', 'yellow_crust_ooze'
  ];

  final Set<String> _selectedSymptoms = {};
  String _prediction = '';
  bool _showResult = false;
  bool _isLoading = false;

  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset('assets/model.tflite', options: interpreterOptions);
      _labels = (await rootBundle.loadString('assets/labels.txt')).split('\n');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _runInference() async {
    if (_interpreter == null || _labels == null) {
      print('Interpreter or labels not loaded');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var inputData = List<double>.filled(132, 0.0);
    for (String symptom in _selectedSymptoms) {
      int index = masterSymptomList.indexOf(symptom);
      if (index != -1) {
        inputData[index] = 1.0;
      }
    }

    print('Input: $inputData');

    try {
      var outputShape = _interpreter!.getOutputTensors()[0].shape;
      var output = List<double>.filled(outputShape[1], 0.0).reshape(outputShape);
      _interpreter!.run([inputData], output);

      print('Output: $output');

      double maxScore = 0;
      int bestLabelIndex = -1;
      for (int i = 0; i < output[0].length; i++) {
        if (output[0][i] > maxScore) {
          maxScore = output[0][i];
          bestLabelIndex = i;
        }
      }

      print('Max Score: $maxScore, Best Label Index: $bestLabelIndex');

      if (bestLabelIndex != -1) {
        _prediction = _labels![bestLabelIndex];
      } else {
        _prediction = 'No disease detected. Please select more symptoms.';
      }
    } catch (e) {
      print('Error running inference: $e');
      _prediction = 'Error analyzing symptoms. Please try again.';
    }

    setState(() {
      _isLoading = false;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...masterSymptomList.map((symptom) {
            return CheckboxListTile(
              title: Text(symptom.replaceAll('_', ' ')),
              value: _selectedSymptoms.contains(symptom),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
            );
          }).toList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _runInference,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Analyze Symptoms'),
          ),
          const SizedBox(height: 20),
          if (_showResult)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediction:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_prediction),
                    const SizedBox(height: 10),
                    const Text(
                      'Disclaimer: This is not a medical diagnosis. Please consult a doctor for accurate advice.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}