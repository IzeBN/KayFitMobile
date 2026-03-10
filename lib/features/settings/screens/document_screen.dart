import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

enum DocumentType { privacyPolicy, termsOfService }

class DocumentScreen extends StatelessWidget {
  final DocumentType type;

  const DocumentScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final title = type == DocumentType.privacyPolicy
        ? (isRu ? 'Политика конфиденциальности' : 'Privacy Policy')
        : (isRu ? 'Пользовательское соглашение' : 'Terms of Service');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        child: type == DocumentType.privacyPolicy
            ? _PrivacyPolicy(isRu: isRu)
            : _TermsOfService(isRu: isRu),
      ),
    );
  }
}

// ─── Privacy Policy ──────────────────────────────────────────────────────────

class _PrivacyPolicy extends StatelessWidget {
  final bool isRu;
  const _PrivacyPolicy({required this.isRu});

  @override
  Widget build(BuildContext context) =>
      isRu ? const _PrivacyPolicyRu() : const _PrivacyPolicyEn();
}

class _PrivacyPolicyRu extends StatelessWidget {
  const _PrivacyPolicyRu();

  @override
  Widget build(BuildContext context) {
    return const _DocContent(sections: [
      _Section(
        title: 'ПОЛИТИКА ОБРАБОТКИ ПЕРСОНАЛЬНЫХ ДАННЫХ',
        body: '',
        isHeadline: true,
      ),
      _Section(
        title: '1. Общие положения',
        body: '1.1. Настоящая Политика разработана в соответствии с Федеральным законом от 27.07.2006 № 152-ФЗ '
            '«О персональных данных» и определяет порядок обработки персональных данных (ПДн) пользователей '
            'приложения «Кайфит».\n\n'
            '1.2. Оператор ПДн: Индивидуальный предприниматель Чистяков Артем Михайлович (ИНН 645006236405).',
      ),
      _Section(
        title: '2. Цели сбора персональных данных',
        body: '• Оказание услуг по предоставлению доступа к функционалу приложения «Кайфит» и исполнение '
            'Пользовательского соглашения.\n'
            '• Персонализация контента, адаптация рекомендаций по осознанному питанию.\n'
            '• Направление информационных уведомлений (при наличии согласия).\n'
            '• Обработка платежей и управление подписками.',
      ),
      _Section(
        title: '3. Объём обрабатываемых данных',
        body: '• Базовые учётные данные: имя (никнейм), email и/или номер телефона.\n'
            '• Данные для персонализации: возраст, вес, рост, цели.\n'
            '• Платёжные данные: частично маскированные реквизиты карт, обрабатываемые банком-эквайером.\n'
            '• Технические данные: IP-адрес, данные устройства.',
      ),
      _Section(
        title: '4. Порядок обработки и защиты',
        body: '4.1. Обработка ПДн осуществляется на законной основе с использованием баз данных '
            'на территории Российской Федерации.\n\n'
            '4.2. Оператор принимает технические и организационные меры для защиты ПДн от неправомерного доступа.\n\n'
            '4.3. Данные не передаются третьим лицам без согласия Пользователя, за исключением случаев, '
            'предусмотренных законодательством РФ, а также передачи платёжным сервисам для проведения транзакций.',
      ),
      _Section(
        title: '5. Права субъекта ПДн',
        body: '5.1. Пользователь вправе в любой момент отозвать согласие на обработку ПДн или запросить '
            'их удаление, направив письмо на: artemeree@gmail.com. После получения запроса аккаунт и '
            'все связанные данные удаляются в установленные законом сроки.',
      ),
      _Section(
        title: 'Реквизиты Администрации',
        body: 'ИП Чистяков Артем Михайлович\nИНН: 645006236405\nОГРНИП: 323645700098707\nE-mail: artemeree@gmail.com',
      ),
    ]);
  }
}

class _PrivacyPolicyEn extends StatelessWidget {
  const _PrivacyPolicyEn();

  @override
  Widget build(BuildContext context) {
    return const _DocContent(sections: [
      _Section(
        title: 'PERSONAL DATA PROCESSING POLICY',
        body: '',
        isHeadline: true,
      ),
      _Section(
        title: '1. General Provisions',
        body: '1.1. This Policy is developed in accordance with applicable data protection law and governs '
            'the processing of personal data of users of the "Kayfit" application.\n\n'
            '1.2. Data Operator: Individual Entrepreneur Artem Chistyakov (TIN 645006236405).',
      ),
      _Section(
        title: '2. Purposes of Data Collection',
        body: '• Providing access to the features of the Kayfit application and fulfilling the Terms of Service.\n'
            '• Personalising content and nutrition recommendations.\n'
            '• Sending informational notifications (only with explicit consent).\n'
            '• Processing payments and managing subscriptions.',
      ),
      _Section(
        title: '3. Scope of Data Processed',
        body: '• Account data: name (nickname), email address and/or phone number.\n'
            '• Personalisation data: age, weight, height, goals.\n'
            '• Payment data: partially masked card details processed by the acquiring bank.\n'
            '• Technical data: IP address, device information.',
      ),
      _Section(
        title: '4. Processing and Protection',
        body: '4.1. Personal data is processed on a lawful basis.\n\n'
            '4.2. The Operator implements technical and organisational measures to protect personal data '
            'from unauthorised access, destruction, alteration, and disclosure.\n\n'
            '4.3. Data is not shared with third parties without the User\'s consent, except as required by law '
            'or for payment processing purposes.',
      ),
      _Section(
        title: '5. Rights of the Data Subject',
        body: '5.1. The User may at any time withdraw consent to data processing or request full deletion '
            'by emailing: artemeree@gmail.com. Upon receiving such a request, the account and all associated '
            'data will be deleted within the timeframes established by law.',
      ),
      _Section(
        title: 'Administrator Details',
        body: 'Individual Entrepreneur: Artem Chistyakov\nTIN: 645006236405\nOGRNIP: 323645700098707\nEmail: artemeree@gmail.com',
      ),
    ]);
  }
}

// ─── Terms of Service ────────────────────────────────────────────────────────

class _TermsOfService extends StatelessWidget {
  final bool isRu;
  const _TermsOfService({required this.isRu});

  @override
  Widget build(BuildContext context) =>
      isRu ? const _TermsRu() : const _TermsEn();
}

class _TermsRu extends StatelessWidget {
  const _TermsRu();

  @override
  Widget build(BuildContext context) {
    return const _DocContent(sections: [
      _Section(
        title: 'ПОЛЬЗОВАТЕЛЬСКОЕ СОГЛАШЕНИЕ СЕРВИСА «КАЙФИТ»',
        body: '',
        isHeadline: true,
      ),
      _Section(
        title: '1. Общие положения',
        body: '1.1. Настоящее Пользовательское соглашение (далее — Соглашение) регулирует отношения между '
            'Индивидуальным предпринимателем Чистяковым Артемом Михайловичем (ОГРНИП: 323645700098707, '
            'ИНН: 645006236405), далее — «Администрация», и любым физическим лицом, использующим '
            'мобильное приложение «Кайфит» (далее — «Приложение»), далее — «Пользователь».\n\n'
            '1.2. Регистрация в Приложении означает безоговорочное принятие Пользователем условий '
            'настоящего Соглашения (акцепт оферты).',
      ),
      _Section(
        title: '2. Предмет соглашения',
        body: '2.1. Администрация предоставляет Пользователю неисключительное право на использование '
            'Приложения «Кайфит» для доступа к информации о питании, трекингу привычек и образовательному '
            'контенту на условиях бесплатного или платного доступа (подписки).\n\n'
            '2.2. Весь контент (тексты, дизайн, алгоритмы, методики) является интеллектуальной '
            'собственностью Администрации.',
      ),
      _Section(
        title: '3. Отказ от ответственности (Медицинская оговорка)',
        body: '3.1. Приложение «Кайфит» носит исключительно информационный характер. '
            'Предоставляемые рекомендации не являются медицинскими консультациями, диагнозами или '
            'планами лечения.\n\n'
            '3.2. Пользователь принимает на себя полную ответственность за своё здоровье. '
            'При наличии хронических заболеваний или расстройств пищевого поведения необходимо '
            'проконсультироваться с лечащим врачом перед использованием Приложения.',
      ),
      _Section(
        title: '4. Права и обязанности сторон',
        body: '4.1. Пользователь обязуется: указывать достоверные данные при регистрации; не передавать '
            'доступ к аккаунту третьим лицам; не использовать материалы в коммерческих целях.\n\n'
            '4.2. Администрация имеет право: вносить изменения в интерфейс и функционал; '
            'приостанавливать доступ при нарушении Соглашения; изменять стоимость подписки '
            'с предварительным уведомлением.',
      ),
      _Section(
        title: '5. Стоимость услуг, тарифы и порядок расчётов',
        body: '5.1. Доступ к расширенному функционалу предоставляется по платной подписке.\n\n'
            '5.2. Доступные тарифные планы:\n'
            '• Пробный период (Trial): 3 дня бесплатно. При активации холдируется 1 руб. '
            'По истечении 3 дней автоматически активируется Годовая подписка (2 990 руб.).\n'
            '• Месячная подписка: 990 руб./мес.\n'
            '• Трёхмесячная подписка: 1 290 руб. за 3 мес. Включает: план питания, гайд по '
            'похудению, 15-мин. консультацию с коучем.\n'
            '• Годовая подписка: 2 990 руб./год (249 руб./мес.).\n\n'
            '5.3. Все тарифы предусматривают автоматическое продление. Совершая оплату, '
            'Пользователь даёт согласие на регулярные списания.\n\n'
            '5.4. Пользователь вправе отменить автопродление через настройки Приложения. '
            'Оплаченный период остаётся доступным до окончания. Возврат за неиспользованный '
            'период не производится, если иное не предусмотрено законодательством РФ.',
      ),
      _Section(
        title: '6. Разрешение споров',
        body: '6.1. Все споры решаются путём переговоров. Срок ответа на претензию — '
            '30 календарных дней с момента получения Администрацией.',
      ),
    ]);
  }
}

class _TermsEn extends StatelessWidget {
  const _TermsEn();

  @override
  Widget build(BuildContext context) {
    return const _DocContent(sections: [
      _Section(
        title: 'TERMS OF SERVICE — KAYFIT',
        body: '',
        isHeadline: true,
      ),
      _Section(
        title: '1. General Provisions',
        body: '1.1. These Terms of Service (the "Agreement") govern the relationship between Individual '
            'Entrepreneur Artem Chistyakov (OGRNIP: 323645700098707, TIN: 645006236405), hereinafter '
            '"Administration", and any individual using the Kayfit mobile application, hereinafter "User".\n\n'
            '1.2. Registering in the Application constitutes unconditional acceptance of this Agreement.',
      ),
      _Section(
        title: '2. Subject of the Agreement',
        body: '2.1. The Administration grants the User a non-exclusive right to use the Kayfit application '
            'for access to nutritional information, habit tracking, and educational content on a free or '
            'paid (subscription) basis.\n\n'
            '2.2. All content (text, design, algorithms, methodologies) is the intellectual property '
            'of the Administration.',
      ),
      _Section(
        title: '3. Disclaimer (Medical Notice)',
        body: '3.1. The Kayfit application is purely informational. The nutrition recommendations, '
            'overeating guidance, and habit tracking features do not constitute medical advice, '
            'diagnoses, or treatment plans.\n\n'
            '3.2. The User bears full responsibility for their health. Users with chronic conditions '
            'or eating disorders must consult a healthcare professional before using the Application.',
      ),
      _Section(
        title: '4. Rights and Obligations',
        body: '4.1. The User agrees to: provide accurate information upon registration; not share account '
            'access with third parties; not use materials for commercial purposes.\n\n'
            '4.2. The Administration reserves the right to: update the interface and features; '
            'suspend access for breaches of this Agreement; modify subscription pricing with prior '
            'in-app notification.',
      ),
      _Section(
        title: '5. Pricing, Plans, and Payments',
        body: '5.1. Access to premium features is provided via paid subscription.\n\n'
            '5.2. Available plans:\n'
            '• Trial (3 days free): a 1 RUB hold is placed on your card for verification. '
            'After 3 days, if not cancelled, an Annual subscription (2,990 RUB) activates automatically.\n'
            '• Monthly: 990 RUB/month.\n'
            '• 3-Month ("Best Value"): 1,290 RUB for 3 months. Includes: personalised meal plan, '
            'weight-loss guide, 15-min coaching session.\n'
            '• Annual: 2,990 RUB/year (249 RUB/month).\n\n'
            '5.3. All plans renew automatically. By making a payment, the User consents to recurring charges.\n\n'
            '5.4. The User may cancel auto-renewal at any time in the Application settings. '
            'The paid period remains accessible until it expires. Refunds for unused periods are '
            'not provided unless required by applicable law.',
      ),
      _Section(
        title: '6. Dispute Resolution',
        body: '6.1. All disputes are resolved through negotiation. The Administration will respond '
            'to official complaints within 30 calendar days of receipt.',
      ),
    ]);
  }
}

// ─── Shared document widgets ─────────────────────────────────────────────────

class _DocContent extends StatelessWidget {
  final List<_Section> sections;
  const _DocContent({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => _SectionWidget(section: s)).toList(),
    );
  }
}

class _Section {
  final String title;
  final String body;
  final bool isHeadline;
  const _Section({required this.title, required this.body, this.isHeadline = false});
}

class _SectionWidget extends StatelessWidget {
  final _Section section;
  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    if (section.isHeadline) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          section.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.3,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (section.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              section.body,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.65,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
