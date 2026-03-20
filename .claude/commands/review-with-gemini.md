이 명령어는 현재 작성된 플랜이나 코드를 제미나이(Gemini)에게 크로스 리뷰 받는 자동화 워크플로우입니다.

1. 현재 작업 중인 플랜이나 코드를 `claude_plan.md` 파일로 저장(export)해.
2. 터미널에서 `dart run scripts/review_ai.dart claude_plan.md` 명령어를 실행해.
3. 스크립트가 반환한 제미나이의 피드백 결과를 읽고, 이를 반영하여 너의 플랜을 수정한 뒤 나에게 브리핑해.