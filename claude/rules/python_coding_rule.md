## Python 코딩 원칙

### PEP 8 스타일 가이드 준수
- **들여쓰기**: 4 스페이스 (탭 사용 금지)
- **최대 줄 길이**: 79자 (코드), 72자 (주석/docstring)
- **빈 줄**:
  - 최상위 함수/클래스 정의 사이: 2줄
  - 클래스 내 메서드 사이: 1줄
- **임포트 순서**:
  1. 표준 라이브러리
  2. 서드파티 라이브러리
  3. 로컬 모듈
  - 각 그룹 사이 빈 줄 삽입

### 네이밍 컨벤션
- **모듈/패키지**: `lowercase`, `lower_with_under`
- **클래스**: `CapWords` (PascalCase)
- **함수/메서드**: `lowercase_with_underscores`
- **상수**: `UPPER_CASE_WITH_UNDERSCORES`
- **private 속성**: `_leading_underscore`
- **내부 사용**: `__double_leading_underscore`

### 타입 힌팅
- Python 3.9+ 타입 힌팅 사용
- 함수 시그니처에 타입 명시
- 복잡한 타입은 `typing` 모듈 활용

```python
from typing import List, Dict, Optional, Union

def process_data(
    items: List[str],
    config: Dict[str, int],
    threshold: Optional[float] = None
) -> Union[List[int], None]:
    """데이터 처리 함수"""
    pass

### Docstring 작성 (Google Style)
- 모든 public 함수, 클래스, 모듈에 docstring 작성
- 첫 줄: 간단한 요약 (마침표로 끝)
- 빈 줄 후 상세 설명
- Args, Returns, Raises 섹션 명시

```python
def calculate_average(numbers: List[float]) -> float:
    """숫자 리스트의 평균을 계산합니다.

    빈 리스트가 입력되면 ValueError를 발생시킵니다.

    Args:
        numbers: 평균을 계산할 숫자 리스트

    Returns:
        입력된 숫자들의 산술 평균

    Raises:
        ValueError: 리스트가 비어있는 경우
    """
    if not numbers:
        raise ValueError("빈 리스트는 처리할 수 없습니다")
    return sum(numbers) / len(numbers)

## 코드 작성 원칙

### 명확성 우선
- 영리한 코드보다 읽기 쉬운 코드
- 매직 넘버 대신 상수 사용
- 복잡한 표현식은 여러 줄로 분리

### SOLID 원칙
- **Single Responsibility**: 클래스/함수는 하나의 책임만
- **Open/Closed**: 확장에는 열려있고 수정에는 닫혀있게
- **Liskov Substitution**: 하위 타입은 상위 타입을 대체 가능해야 함
- **Interface Segregation**: 인터페이스는 작고 구체적으로
- **Dependency Inversion**: 추상화에 의존, 구체화 의존 금지

### DRY (Don't Repeat Yourself)
- 중복 코드 제거
- 공통 로직은 함수/클래스로 추출
- 설정은 변수/상수로 관리

### 에러 처리
- 명시적인 예외 처리
- 구체적인 예외 타입 사용
- 예외 메시지에 맥락 정보 포함

```python
try:
    result = risky_operation()
except FileNotFoundError as e:
    logger.error(f"파일을 찾을 수 없음: {e.filename}")
    raise
except ValueError as e:
    logger.warning(f"잘못된 값: {e}")
    return default_value

### 모듈 구성
- `__init__.py`: 패키지 초기화, public API 정의
- 하나의 모듈 = 하나의 주제
- 관련된 기능끼리 그룹화

## 커뮤니케이션 원칙

### 코드 주석
- **언제 작성**: WHY를 설명 (WHAT은 코드로 충분)
- **한글 사용**: 한국어 프로젝트는 주석도 한글
- **최신 유지**: 코드 변경 시 주석도 업데이트

### 커밋 메시지
- 명령형 현재 시제: "Add feature" (not "Added")
- 첫 줄: 50자 이내 요약
- 본문: 변경 이유 설명

### 코드 리뷰 요청 시
- 변경 사항 요약 제공
- 테스트 결과 포함
- 알려진 이슈 명시

## 테스트 작성

### pytest 기본 원칙
- 테스트 함수명: `test_` 접두사
- 테스트 파일명: `test_*.py` 형식
- 1 테스트 = 1 검증 대상
- AAA 패턴: Arrange, Act, Assert

python
def test_calculate_average_with_valid_input():
    # Arrange
    numbers = [1.0, 2.0, 3.0, 4.0, 5.0]

    # Act
    result = calculate_average(numbers)

    # Assert
    assert result == 3.0

### 엣지 케이스 테스트
- 빈 입력
- None 값
- 경계값
- 예외 상황

## 작업 진행 방식

### 코드 작성 전
1. 요구사항 명확히 이해
2. 기존 코드 파악
3. 설계 고민 (필요 시)

### 코드 수정 시
1. 백업 또는 Git 커밋 확인
2. 변경 범위 최소화
3. 테스트로 검증

### 완료 기준
- 코드 동작 검증
- 타입 체크 통과
- 테스트 작성 완료
- 문서 업데이트

## 금지 사항

### 절대 하지 말 것
- ❌ `import *` 사용
- ❌ Mutable 기본 인자 (`def func(items=[])`)
- ❌ 전역 변수 남용
- ❌ 하드코딩된 경로/비밀번호
- ❌ 의미 없는 변수명 (`a`, `tmp`, `data`)

### 주의할 것
- ⚠️ 너무 긴 함수 (20줄 초과 시 분리 고려)
- ⚠️ 깊은 중첩 (3단계 초과 시 리팩토링)
- ⚠️ 순환 임포트
- ⚠️ Exception 포괄 처리 (`except Exception`)