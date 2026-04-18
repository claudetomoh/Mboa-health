import 'package:flutter/foundation.dart';

// =============================================================================
// MBOA HEALTH — Symptom Checker Provider
// Rule-based clinical symptom analysis engine.
// Covers common conditions prevalent in Cameroon / West Africa.
// =============================================================================

/// The result of a rule-based symptom analysis.
class SymptomAnalysis {
  final String condition;
  final String summary;

  /// 'low' | 'medium' | 'high' | 'emergency'
  final String urgency;

  final List<String> recommendations;
  final List<String> symptoms;

  /// Suggested clinic speciality.
  final String clinicType;

  const SymptomAnalysis({
    required this.condition,
    required this.summary,
    required this.urgency,
    required this.recommendations,
    required this.symptoms,
    this.clinicType = 'General Practice',
  });
}

class SymptomCheckerProvider extends ChangeNotifier {
  List<String> _selectedSymptoms = [];
  SymptomAnalysis? _analysis;

  List<String>    get selectedSymptoms => List.unmodifiable(_selectedSymptoms);
  SymptomAnalysis? get analysis        => _analysis;

  // ── Symptom selection ─────────────────────────────────────────────────────

  void addSymptom(String symptom) {
    if (!_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms = [..._selectedSymptoms, symptom];
      _analysis = null; // reset previous result when list changes
      notifyListeners();
    }
  }

  void removeSymptom(String symptom) {
    _selectedSymptoms =
        _selectedSymptoms.where((s) => s != symptom).toList();
    _analysis = null;
    notifyListeners();
  }

  void clearAll() {
    _selectedSymptoms = [];
    _analysis = null;
    notifyListeners();
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  /// Runs the rule-based engine and stores the result.
  void analyze() {
    _analysis = _runRuleEngine(_selectedSymptoms);
    notifyListeners();
  }

  // ── Rule engine ───────────────────────────────────────────────────────────

  static SymptomAnalysis _runRuleEngine(List<String> symptoms) {
    // Normalize to lowercase for matching
    final s = symptoms.map((e) => e.toLowerCase()).toList();

    if (symptoms.isEmpty) {
      return const SymptomAnalysis(
        condition: 'No Symptoms Selected',
        summary:
            'Please select at least one symptom to receive a clinical assessment.',
        urgency: 'low',
        recommendations: [
          'Select your symptoms from the list above.',
          'Tap a suggestion card or type in the search bar.',
        ],
        symptoms: [],
      );
    }

    // ── EMERGENCY ────────────────────────────────────────────────────────────

    if ((_hasAll(s, ['chest pain', 'shortness of breath'])) ||
        (_hasAny(s, ['chest pain']) &&
            _hasAny(s, ['arm pain', 'jaw pain', 'sweating']))) {
      return SymptomAnalysis(
        condition: 'Possible Cardiac Emergency',
        summary:
            'Chest pain combined with other symptoms may indicate a serious cardiac event requiring immediate care.',
        urgency: 'emergency',
        recommendations: [
          'Call emergency services (15) immediately',
          'Do not walk — remain seated and calm',
          'Loosen tight clothing',
          'Alert someone nearby to stay with you',
          'If advised by a doctor, take aspirin 325 mg',
        ],
        symptoms: symptoms,
        clinicType: 'Emergency',
      );
    }

    if (_hasAll(s, ['fever', 'stiff neck']) ||
        _hasAll(s, ['high fever', 'stiff neck'])) {
      return SymptomAnalysis(
        condition: 'Possible Meningitis',
        summary:
            'Fever and stiff neck together are classic warning signs of meningitis — a medical emergency.',
        urgency: 'emergency',
        recommendations: [
          'Seek emergency care immediately — call 15',
          'Avoid bright lights and loud sounds',
          'Do not delay treatment',
          'Alert family members of your condition',
        ],
        symptoms: symptoms,
        clinicType: 'Emergency',
      );
    }

    // ── MALARIA (common in Cameroon) ──────────────────────────────────────────

    if (_hasAny(s, ['chills', 'shivering', 'rigors']) &&
        _hasAny(s, ['fever', 'high fever']) &&
        _hasAny(s, ['headache', 'body ache', 'fatigue', 'sweating'])) {
      return SymptomAnalysis(
        condition: 'Possible Malaria',
        summary:
            'Cyclical fevers with chills, sweating and body aches are classic malaria indicators common in Cameroon.',
        urgency: 'high',
        recommendations: [
          'Seek medical care promptly for a malaria rapid test (RDT)',
          'Do not self-medicate with antimalarials until confirmed positive',
          'Stay hydrated and rest in a cool place',
          'Sleep under a mosquito net',
          'Monitor for worsening or confusion — seek emergency care if present',
        ],
        symptoms: symptoms,
      );
    }

    // ── VIRAL RESPIRATORY INFECTION ───────────────────────────────────────────

    if (_hasAny(s, ['cough', 'sore throat', 'runny nose', 'nasal congestion']) &&
        _hasAny(s, ['fever', 'fatigue', 'headache', 'body ache'])) {
      return SymptomAnalysis(
        condition: 'Mild Viral Respiratory Infection',
        summary:
            'Your symptoms suggest a common cold or flu-like viral infection.',
        urgency: 'low',
        recommendations: [
          'Increase fluid intake to at least 2.5 L/day',
          'Get a minimum of 8 hours of rest',
          'Monitor your temperature every 6 hours',
          'Take paracetamol (500 mg) for fever above 38.5 °C',
          'Consult a doctor if symptoms persist beyond 5 days',
        ],
        symptoms: symptoms,
      );
    }

    // ── MIGRAINE ──────────────────────────────────────────────────────────────

    if (_hasAny(s, ['migraine', 'severe headache', 'throbbing headache']) &&
        _hasAny(s, ['nausea', 'light sensitivity', 'blurred vision',
            'visual aura', 'dizziness', 'vomiting'])) {
      return SymptomAnalysis(
        condition: 'Migraine Episode',
        summary:
            'Your symptom pattern closely matches a classic migraine attack.',
        urgency: 'medium',
        recommendations: [
          'Rest in a quiet, darkened room',
          'Apply a cold compress to your forehead or neck',
          'Take your prescribed migraine medication or ibuprofen 400 mg',
          'Stay hydrated — sip water slowly',
          'Avoid screens and bright lights for several hours',
          'Track triggers in a diary for future prevention',
        ],
        symptoms: symptoms,
        clinicType: 'Neurology / General Practice',
      );
    }

    // ── GASTROENTERITIS ───────────────────────────────────────────────────────

    if (_hasAny(s, [
          'stomach pain',
          'abdominal pain',
          'diarrhea',
          'vomiting',
          'stomach cramps',
        ]) &&
        _hasAny(s, ['nausea', 'fever', 'cramping', 'loss of appetite'])) {
      return SymptomAnalysis(
        condition: 'Acute Gastroenteritis',
        summary:
            'Stomach pain, nausea, and diarrhea typically indicate a gastrointestinal infection.',
        urgency: 'medium',
        recommendations: [
          'Drink oral rehydration salts (ORS) regularly',
          'Eat only bland foods: rice, toast, bananas',
          'Avoid dairy, spicy, or fatty foods',
          'Seek care if symptoms last beyond 48 hours',
          'Watch for signs of dehydration: dry mouth, no urine, weakness',
        ],
        symptoms: symptoms,
      );
    }

    // ── HYPERTENSION RISK ─────────────────────────────────────────────────────

    if (_hasAny(s, ['dizziness', 'palpitations', 'heart pounding']) &&
        _hasAny(s, ['headache', 'blurred vision', 'chest tightness',
            'shortness of breath'])) {
      return SymptomAnalysis(
        condition: 'Possible Hypertensive Episode',
        summary:
            'Your symptoms may suggest elevated blood pressure requiring prompt evaluation.',
        urgency: 'high',
        recommendations: [
          'Measure your blood pressure immediately if possible',
          'Sit and rest in a calm, cool environment',
          'Avoid caffeine, salt, and any physical exertion',
          'Consult a doctor for blood pressure evaluation today',
          'Call emergency services if chest pain intensifies',
        ],
        symptoms: symptoms,
        clinicType: 'Cardiology / General Practice',
      );
    }

    // ── DIABETES SYMPTOMS ─────────────────────────────────────────────────────

    if (_hasAny(
            s, ['excessive thirst', 'frequent urination', 'increased urination']) &&
        _hasAny(s, ['fatigue', 'blurred vision', 'weight loss', 'hunger'])) {
      return SymptomAnalysis(
        condition: 'Possible Hyperglycemia',
        summary:
            'Increased thirst and urination combined with fatigue may indicate elevated blood sugar.',
        urgency: 'medium',
        recommendations: [
          'Check blood sugar with a glucometer if available',
          'Reduce sugary food and drinks immediately',
          'Drink water regularly',
          'Consult a doctor for blood glucose testing',
          'Seek emergency care if you feel confused or very weak',
        ],
        symptoms: symptoms,
        clinicType: 'Endocrinology / General Practice',
      );
    }

    // ── MUSCULOSKELETAL PAIN ──────────────────────────────────────────────────

    if (_hasAny(s, [
          'joint pain',
          'back pain',
          'muscle pain',
          'body ache',
          'neck pain',
          'knee pain',
        ]) &&
        !_hasAny(s, ['fever', 'rash', 'swelling', 'redness'])) {
      return SymptomAnalysis(
        condition: 'Musculoskeletal Pain',
        summary:
            'Your joint or muscle aches are likely due to strain, overexertion, or tension.',
        urgency: 'low',
        recommendations: [
          'Rest the affected area for 24–48 hours',
          'Apply a warm or cold compress — alternate every 20 minutes',
          'Take ibuprofen 400 mg for pain if no contraindications',
          'Begin gentle stretching after initial rest period',
          'See a physiotherapist if pain persists beyond one week',
        ],
        symptoms: symptoms,
        clinicType: 'General Practice / Physiotherapy',
      );
    }

    // ── ANXIETY / STRESS ──────────────────────────────────────────────────────

    if (_hasAll(s, ['palpitations', 'shortness of breath']) &&
        !_hasAny(s, ['chest pain', 'fever', 'swelling'])) {
      return SymptomAnalysis(
        condition: 'Possible Anxiety or Stress Response',
        summary:
            'Palpitations and breathing difficulty without chest pain can be related to stress or anxiety.',
        urgency: 'low',
        recommendations: [
          'Practice deep breathing: inhale 4s, hold 7s, exhale 8s',
          'Rest in a calm, cool space',
          'Avoid caffeine, energy drinks, and stimulants',
          'Talk to someone you trust about any current stressors',
          'Consult a doctor if episodes are frequent or intensifying',
        ],
        symptoms: symptoms,
        clinicType: 'Mental Health / General Practice',
      );
    }

    // ── TYPHOID ───────────────────────────────────────────────────────────────

    if (_hasAny(s, ['prolonged fever', 'sustained fever']) &&
        _hasAny(s, ['abdominal pain', 'constipation', 'diarrhea']) &&
        _hasAny(s, ['fatigue', 'weakness', 'loss of appetite'])) {
      return SymptomAnalysis(
        condition: 'Possible Typhoid Fever',
        summary:
            'Prolonged fever with abdominal symptoms and fatigue are characteristic of typhoid, common in Cameroon.',
        urgency: 'high',
        recommendations: [
          'Seek medical care for a Widal test or blood culture',
          'Do not self-medicate with antibiotics',
          'Stay hydrated with clean boiled water',
          'Eat soft, easily digestible foods',
          'Isolate and practise strict hand hygiene',
        ],
        symptoms: symptoms,
        clinicType: 'General Practice / Infectious Disease',
      );
    }

    // ── GENERIC FALLBACK ─────────────────────────────────────────────────────

    return SymptomAnalysis(
      condition: 'Unspecified Symptom Pattern',
      summary:
          'The reported symptoms require further clinical evaluation to determine a specific condition.',
      urgency: 'medium',
      recommendations: [
        'Consult a qualified healthcare provider',
        'Document your symptoms with dates and severity',
        'Monitor for any worsening of symptoms',
        'Stay hydrated and get adequate rest',
        'Avoid self-medication until a diagnosis is confirmed',
      ],
      symptoms: symptoms,
    );
  }

  // ── Pattern helpers ───────────────────────────────────────────────────────

  /// All of [required] appear somewhere in [symptoms] (fuzzy substring match).
  static bool _hasAll(List<String> symptoms, List<String> required) =>
      required.every((r) =>
          symptoms.any((s) => s.contains(r) || r.contains(s)));

  /// At least one of [any] appears in [symptoms].
  static bool _hasAny(List<String> symptoms, List<String> any) =>
      any.any((r) => symptoms.any((s) => s.contains(r) || r.contains(s)));
}
