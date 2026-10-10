import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/assignment_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/app_image_widget.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classItem;
  final UserModel teacher;

  const ClassDetailScreen({
    super.key,
    required this.classItem,
    required this.teacher,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAwardPointsDialog(UserModel student) {
    bool isAddPoints = true;
    final pointsController = TextEditingController(text: '10');
    final reasonController = TextEditingController(text: 'Ders gayreti ve edep ödülü');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isAddPoints ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                    color: isAddPoints ? AppTheme.successColor : AppTheme.errorColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${student.fullName}\'ye Puan Değerlendirmesi',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('+ Artı Puan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              selected: isAddPoints,
                              selectedColor: AppTheme.successColor,
                              backgroundColor: Colors.grey.shade200,
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    isAddPoints = true;
                                    reasonController.text = 'Ders gayreti ve edep ödülü';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.remove, size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('- Eksi Puan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              selected: !isAddPoints,
                              selectedColor: AppTheme.errorColor,
                              backgroundColor: Colors.grey.shade200,
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    isAddPoints = false;
                                    reasonController.text = 'Ders/ödev eksikliği';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: (isAddPoints ? [5, 10, 20, 50] : [5, 10, 15, 20]).map((pts) {
                          return ActionChip(
                            label: Text(
                              isAddPoints ? '+$pts' : '-$pts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAddPoints ? AppTheme.successColor : AppTheme.errorColor,
                              ),
                            ),
                            backgroundColor: isAddPoints
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.errorColor.withValues(alpha: 0.1),
                            onPressed: () {
                              setDialogState(() {
                                pointsController.text = '$pts';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAddPoints ? 'Verilecek Artı Puan' : 'Düşülecek Eksi Puan',
                          prefixIcon: Icon(
                            isAddPoints ? Icons.add_rounded : Icons.remove_rounded,
                            color: isAddPoints ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Puan Verme / Düşme Nedeni',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(110, 42),
                    backgroundColor: isAddPoints ? AppTheme.primaryColor : AppTheme.errorColor,
                  ),
                  onPressed: () {
                    final amount = int.tryParse(pointsController.text) ?? 10;
                    final pts = isAddPoints ? amount : -amount;

                    DataService.instance.awardPointsToStudent(
                      student.id,
                      pts,
                      reasonController.text,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAddPoints
                              ? '${student.fullName}\'ye +$amount Artı Puan eklendi!'
                              : '${student.fullName}\'den -$amount Eksi Puan düşüldü!',
                        ),
                        backgroundColor: isAddPoints ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    );
                  },
                  child: Text(isAddPoints ? 'Puan Ekle' : 'Puan Düş'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConfirmRemoveStudentDialog(UserModel student, ClassModel currentClass) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_remove_rounded, color: AppTheme.errorColor, size: 28),
              SizedBox(width: 8),
              Text('Emin Misiniz?'),
            ],
          ),
          content: Text(
            '\'${student.fullName}\' isimli talebeyi \'${currentClass.title}\' sınıfından çıkarmak istediğinize emin misiniz?',
            style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                minimumSize: const Size(110, 42),
              ),
              onPressed: () {
                final success = DataService.instance.removeStudentFromTeacherClasses(
                  widget.teacher.id,
                  student.id,
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${student.fullName} sınıftan çıkarıldı.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: const Text('Sınıftan Çıkar'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDeleteAssignmentDialog(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 28),
              SizedBox(width: 8),
              Text('Emin Misiniz?'),
            ],
          ),
          content: Text(
            '\'${assignment.title}\' ödevini silmek istediğinize emin misiniz?\n\nBu ödev silindiğinde talebelerin yanıtları da silinecektir.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                minimumSize: const Size(100, 42),
              ),
              onPressed: () {
                final success = DataService.instance.deleteAssignment(assignment.id);

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('\'${assignment.title}\' ödevi silindi.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: const Text('Ödevi Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showSubmissionsModal(AssignmentModel assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Talebe Cevapları (${assignment.submissions.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'Ödev: ${assignment.title}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  if (assignment.submissions.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Henüz bu ödeve cevap gönderen talebe bulunmuyor.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: assignment.submissions.length,
                        itemBuilder: (context, index) {
                          final submission = assignment.submissions[index];
                          final isEvaluated = submission.isEvaluated;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        submission.studentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        isEvaluated ? '+${submission.score} Puan' : 'Değerlendirilmedi',
                                        style: TextStyle(
                                          color: isEvaluated ? AppTheme.successColor : AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(submission.answerText, style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DataService.instance, AuthService.instance]),
      builder: (context, _) {
        final currentClasses = DataService.instance.getClassesByTeacher(widget.teacher.id);
        final currentClass = currentClasses.firstWhere(
          (c) => c.id == widget.classItem.id || c.code == widget.classItem.code,
          orElse: () => widget.classItem,
        );

        final enrolledStudents = currentClass.studentIds.map((studentId) {
          return AuthService.instance.allUsers.firstWhere(
            (u) => u.id == studentId,
            orElse: () => UserModel(
              id: studentId,
              fullName: studentId == 'u2'
                  ? 'Mehmet Demir'
                  : (studentId == 'u3' ? 'Zeynep Kaya' : 'Talebe ($studentId)'),
              email: 'talebe@ifran.com',
              role: UserRole.talebe,
            ),
          );
        }).toList();

        final classAssignments = DataService.instance
            .getAssignmentsForClass(currentClass.code)
          ..sort((a, b) => b.id.compareTo(a.id));

        return Scaffold(
          appBar: AppBar(
            title: Text(currentClass.title),
          ),
          body: Column(
            children: [
              // Class Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentClass.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: currentClass.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sınıf Kodu Kopyalandı: ${currentClass.code}')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  currentClass.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentClass.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${enrolledStudents.length} Talebe Kayıtlı',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${classAssignments.length} Aktif Ödev',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // TabBar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'Sınıf Talebeleri (${enrolledStudents.length})', icon: const Icon(Icons.people, size: 20)),
                    Tab(text: 'Sınıf Ödevleri (${classAssignments.length})', icon: const Icon(Icons.assignment, size: 20)),
                  ],
                ),
              ),

              // TabBar Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Sınıf Talebeleri
                    _buildStudentsTab(enrolledStudents, currentClass),

                    // Tab 2: Sınıf Ödevleri
                    _buildAssignmentsTab(classAssignments),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentsTab(List<UserModel> students, ClassModel currentClass) {
    if (students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Bu sınıfa henüz hiçbir talebe katılmamış.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sınıf kodunu (${currentClass.code}) talebelerinize vererek sınıfa katılmalarını sağlayabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'T',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(student.email, style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${student.points} P',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                  tooltip: 'Puan Ver / Düş',
                  onPressed: () => _showAwardPointsDialog(student),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, color: AppTheme.errorColor),
                  tooltip: 'Sınıftan Çıkar',
                  onPressed: () => _showConfirmRemoveStudentDialog(student, currentClass),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab(List<AssignmentModel> classAssignments) {
    if (classAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Bu sınıfa henüz özel ödev verilmemiş.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classAssignments.length,
      itemBuilder: (context, index) {
        final assignment = classAssignments[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Max ${assignment.points} Puan',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  assignment.description,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                ),
                if (assignment.imageUrl != null && assignment.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => showFullScreenImageViewer(context, assignment.imageUrl!),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppImageWidget(
                            imageUrl: assignment.imageUrl!,
                            height: 160,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Tam Ekran / Büyüt', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                      tooltip: 'Ödevi Sil',
                      onPressed: () => _showConfirmDeleteAssignmentDialog(assignment),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _showSubmissionsModal(assignment),
                      icon: const Icon(Icons.question_answer_rounded, size: 16),
                      label: Text(
                        'Cevapları Gör (${assignment.submissions.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
