import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';

import '../../repository/response/authority/account_authority_response.dart';
import '../../util/app_dialog.dart';
import '../base_view.dart';
import 'authority_view_model.dart';
import 'authority_view.state.dart';

/// ----------------------------------------------------------------------------
/// [AccountPermissionScreen]
/// 계좌 권한 관리 화면입니다.
/// 기능:
/// 1. 감찰부 모니터링 허용/차단 토글
/// 2. 사용자 ID 검색 및 권한(이체/조회) 추가
/// 3. 기존 등록된 사용자 권한 삭제
/// 4. 변경사항 최종 저장 (API 호출)
/// ----------------------------------------------------------------------------
class AccountPermissionScreen extends ConsumerStatefulWidget {
  final String accountNumber;

  const AccountPermissionScreen({
    super.key,
    this.accountNumber = ""
  });

  @override
  ConsumerState<AccountPermissionScreen> createState() => _AccountPermissionScreenState();
}

class _AccountPermissionScreenState extends ConsumerState<AccountPermissionScreen> {
  // 사용자 추가를 위한 입력 컨트롤러
  final TextEditingController _idController = TextEditingController();
  // 선택된 권한 타입 (기본값: ALL-이체권한)
  String _targetPermission = 'ALL';


  @override
  void initState() {
    super.initState();
    // 1. 화면 진입 시 서버에서 현재 권한 목록과 감찰 설정을 가져옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountAuthorityViewModelProvider.notifier).fetchPermissions(widget.accountNumber);
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // 🔹 [상태 리스너 1] 에러 발생 감지 -> 팝업 표시
    ref.listen<AccountAuthorityState>(accountAuthorityViewModelProvider, (previous, next) {
      if (next.isError && (previous?.isError == false)) {
        AppDialog.showError(
          context,
          message: next.errorMessage ?? "알 수 없는 오류가 발생했습니다.",
          onConfirm: () => Navigator.pop(context),
        );
      }
    });

    // 🔹 [상태 리스너 2] 승인 대기 상태 감지 (관리자 승인 필요 시)
    ref.listen<AccountAuthorityState>(accountAuthorityViewModelProvider, (previous, next) {
      if (next.isPending && (previous?.isPending == false)) {
        AppDialog.showError(
          context,
          message: "관리자 승인 대기 중입니다.",
          onConfirm: () => Navigator.pop(context),
        );
      }
    });

    return BaseView<AuthorityViewModel, AccountAuthorityState>(
      viewModelProvider: accountAuthorityViewModelProvider,
      backgroundColor: ref.color.background,
      appBar: AppBar(
        title: Text(widget.accountNumber,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: ref.color.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      builder: (ref, viewModel, state) {

        // 2. 권한 목록 필터링 (UI 표시용)
        // ALL: 이체 + 조회 권한
        final List<Permission> groupAll = state.permissions
            .where((u) => u.type == 'ALL')
            .toList();
        // VIEW: 조회 전용 권한
        final List<Permission> groupView = state.permissions
            .where((u) => u.type == 'VIEW')
            .toList();

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // [섹션 1] 감찰부 모니터링 설정 (토글)
                        _buildAuditSection(viewModel, state),

                        const SizedBox(height: 30),

                        // [섹션 2] 사용자 검색 및 추가 폼
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildSectionTitle("사용자 추가"),
                            // 사용자 검색 실패 시 에러 메시지 표시
                            if (state.userSearchErrorMessage != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                state.userSearchErrorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                        // ID 입력창 + 추가 버튼 + 라디오 버튼
                        _buildInputForm(viewModel, state.permissions),

                        const SizedBox(height: 32),

                        // [섹션 3] 등록된 사용자 목록 표시
                        _buildSectionTitle("등록된 사용자"),

                        // (1) 이체 권한 그룹 (ALL)
                        _buildPermissionGroupCard(
                          title: '이체 권한',
                          users: groupAll,
                          colorTheme: Colors.deepOrange,
                          icon: Icons.vpn_key_rounded,
                          description: '조회 및 이체가 가능합니다.',
                          viewModel: viewModel,
                        ),

                        const SizedBox(height: 16),

                        // (2) 조회 권한 그룹 (VIEW)
                        _buildPermissionGroupCard(
                          title: '조회 권한',
                          users: groupView,
                          colorTheme: Colors.teal,
                          icon: Icons.remove_red_eye_rounded,
                          description: '조회만 가능합니다.',
                          viewModel: viewModel,
                        ),

                        const SizedBox(height: 150), // 하단 버튼에 가려지지 않도록 여백 확보
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // [하단 고정] 저장 버튼
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildBottomActionButtons(viewModel),
            ),
          ],
        );
      },
    );
  }

  // --- Components ---

  // 감찰부 설정 카드
  Widget _buildAuditSection(AuthorityViewModel viewModel, AccountAuthorityState state) {
    final bool isEnabled = state.isAuditorAllowed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900], // 다크 테마 느낌의 카드
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.security, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('감찰부 모니터링', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  isEnabled ? '현재 모니터링 중입니다.' : '접근이 차단되었습니다.',
                  style: TextStyle(color: isEnabled ? Colors.greenAccent : Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          // 토글 스위치: ViewModel의 상태 변경 메서드 호출
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: isEnabled,
              activeColor: Colors.greenAccent,
              activeTrackColor: Colors.greenAccent.withOpacity(0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[700],
              onChanged: (v) {
                viewModel.toggleAudit(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 권한 그룹 카드 (사용자 목록 리스트)
  Widget _buildPermissionGroupCard({
    required String title,
    required List<Permission> users,
    required MaterialColor colorTheme,
    required IconData icon,
    required String description,
    required AuthorityViewModel viewModel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // 헤더: 타이틀 및 사용자 수 표시
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorTheme.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colorTheme, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorTheme[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${users.length}명', style: TextStyle(color: colorTheme, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100], thickness: 1),

          // 사용자 리스트
          users.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(30.0),
            child: Text('등록된 사용자가 없습니다.', style: TextStyle(color: Colors.grey[400])),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // 부모 스크롤 사용
            itemCount: users.length,
            separatorBuilder: (c, i) => Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: ListTile(
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(user.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  subtitle: Text(user.userId, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    // 삭제 버튼: ViewModel에서 삭제 처리 (로컬 상태만 먼저 변경)
                    onPressed: () {
                      viewModel.removeUser(user.userId);
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 사용자 추가 입력 폼
  Widget _buildInputForm(AuthorityViewModel viewModel , List<Permission> sf) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _idController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "ID 입력",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ref.color.primary.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final inputId = _idController.text.trim();
                  if (inputId.isEmpty) return;

                  // 1. 사용자 검색 및 목록에 추가 요청
                  await viewModel.searchAndAddUser(permissionType: _targetPermission, targetUserId: inputId);

                  // 2. 키보드 내리기 & 입력창 초기화
                  FocusScope.of(context).unfocus();
                  _idController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:  ref.color.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text("추가", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 권한 타입 선택 (이체 / 조회)
        Row(
          children: [
            Expanded(child: _buildRadioButton('ALL', '이체', Colors.deepOrange)),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioButton('VIEW', '조회', Colors.teal)),
          ],
        )
      ],
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
    );
  }

  // 라디오 버튼 스타일 위젯
  Widget _buildRadioButton(String value, String label, Color color) {
    final isSelected = _targetPermission == value;
    return GestureDetector(
      onTap: () => setState(() => _targetPermission = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5
            ),
            boxShadow: [
              if(!isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
            ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                value == 'ALL' ? Icons.vpn_key : Icons.remove_red_eye,
                size: 18,
                color: isSelected ? color : Colors.grey[400]
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  color: isSelected ? color : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 14
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 '저장' 버튼 영역
  Widget _buildBottomActionButtons(AuthorityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // 1. 현재 변경된 상태를 가져와서 확인 팝업 호출
              final currentState = ref.read(accountAuthorityViewModelProvider);
              _showConfirmationDialog(context, viewModel, currentState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:  ref.color.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('저장', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // 최종 확인 다이얼로그 (변경 사항 요약 및 전송)
  void _showConfirmationDialog(BuildContext context, AuthorityViewModel viewModel, AccountAuthorityState state) {
    // 요약 데이터 준비
    final all = state.permissions.where((p) => p.type == 'ALL').map((p) => p.userId).toList();
    final view = state.permissions.where((p) => p.type == 'VIEW').map((p) => p.userId).toList();
    final bool auditOn = state.isAuditorAllowed;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("권한 정보", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 감찰부 설정 요약
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("감찰부 모니터링", style: TextStyle(color: Colors.black87, fontSize: 14)),
                Text(
                  auditOn ? "허용 (ON)" : "차단 (OFF)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: auditOn ? Colors.blue[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),

            // 권한별 사용자 목록 요약
            _infoBox("이체 권한 (${all.length}명)", all.isEmpty ? "-" : all.join(", ")),
            const SizedBox(height: 12),
            _infoBox("조회 권한 (${view.length}명)", view.isEmpty ? "-" : view.join(", ")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. 다이얼로그 닫기
              Navigator.pop(dialogContext);

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              // 2. 서버에 변경 사항 전송 (API 호출)
              final isSuccess = await viewModel.submitChanges(widget.accountNumber);

              // 3. 성공 시 메시지 표시 및 화면 종료
              if (mounted) {
                if (isSuccess) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('권한 변경 요청이 완료되었습니다.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  navigator.pop(); // 설정 화면 닫기
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ref.color.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // 다이얼로그 내부 정보 박스
  Widget _infoBox(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 100), // 최대 높이 제한
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}