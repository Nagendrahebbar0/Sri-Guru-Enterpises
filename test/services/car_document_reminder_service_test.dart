import 'package:flutter_test/flutter_test.dart';
import 'package:sri_guru_enterprise/services/car_document_reminder_service.dart';

void main() {
  group('CarDocumentReminderService', () {
    final DateTime today = DateTime(2026, 9, 3);

    test('returns correct days until expiry', () {
      final DateTime expiry = DateTime(2026, 10, 3);

      expect(
        CarDocumentReminderService.daysUntilExpiry(
          expiry,
          today: today,
        ),
        30,
      );
    });

    test('ignores time of day when calculating days', () {
      final DateTime expiry = DateTime(2026, 9, 10, 23, 59);
      final DateTime current = DateTime(2026, 9, 3, 1, 5);

      expect(
        CarDocumentReminderService.daysUntilExpiry(
          expiry,
          today: current,
        ),
        7,
      );
    });

    test('detects due today', () {
      final DateTime expiry = DateTime(2026, 9, 3);

      expect(
        CarDocumentReminderService.isDueToday(
          expiry,
          today: today,
        ),
        isTrue,
      );
    });

    test('detects overdue', () {
      final DateTime expiry = DateTime(2026, 9, 2);

      expect(
        CarDocumentReminderService.isOverdue(
          expiry,
          today: today,
        ),
        isTrue,
      );
    });

    test('30 day reminder is due', () {
      final DateTime expiry = DateTime(2026, 10, 3);

      expect(
        CarDocumentReminderService.isReminderDue(
          expiry,
          today: today,
        ),
        isTrue,
      );

      expect(
        CarDocumentReminderService.getReminderDays(
          expiry,
          today: today,
        ),
        30,
      );
    });

    test('15 day reminder is due', () {
      final DateTime expiry = DateTime(2026, 9, 18);

      expect(
        CarDocumentReminderService.isReminderDue(
          expiry,
          today: today,
        ),
        isTrue,
      );

      expect(
        CarDocumentReminderService.getReminderDays(
          expiry,
          today: today,
        ),
        15,
      );
    });

    test('7 day reminder is due', () {
      final DateTime expiry = DateTime(2026, 9, 10);

      expect(
        CarDocumentReminderService.isReminderDue(
          expiry,
          today: today,
        ),
        isTrue,
      );

      expect(
        CarDocumentReminderService.getReminderDays(
          expiry,
          today: today,
        ),
        7,
      );
    });

    test('1 day reminder is due', () {
      final DateTime expiry = DateTime(2026, 9, 4);

      expect(
        CarDocumentReminderService.isReminderDue(
          expiry,
          today: today,
        ),
        isTrue,
      );

      expect(
        CarDocumentReminderService.getReminderDays(
          expiry,
          today: today,
        ),
        1,
      );
    });

    test('non-reminder date is not a scheduled reminder', () {
      final DateTime expiry = DateTime(2026, 9, 12);

      expect(
        CarDocumentReminderService.isReminderDue(
          expiry,
          today: today,
        ),
        isFalse,
      );

      expect(
        CarDocumentReminderService.getReminderDays(
          expiry,
          today: today,
        ),
        isNull,
      );
    });

    test('active reminder includes due today', () {
      final DateTime expiry = DateTime(2026, 9, 3);

      expect(
        CarDocumentReminderService.hasActiveReminder(
          expiry,
          today: today,
        ),
        isTrue,
      );
    });

    test('active reminder includes overdue documents', () {
      final DateTime expiry = DateTime(2026, 8, 31);

      expect(
        CarDocumentReminderService.hasActiveReminder(
          expiry,
          today: today,
        ),
        isTrue,
      );
    });

    test('active reminder includes scheduled reminder days', () {
      final DateTime expiry = DateTime(2026, 9, 10);

      expect(
        CarDocumentReminderService.hasActiveReminder(
          expiry,
          today: today,
        ),
        isTrue,
      );
    });

    test('status is Expired', () {
      final DateTime expiry = DateTime(2026, 9, 2);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Expired',
      );
    });

    test('status is Due Today', () {
      final DateTime expiry = DateTime(2026, 9, 3);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Due Today',
      );
    });

    test('status is Reminder Due', () {
      final DateTime expiry = DateTime(2026, 9, 10);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Reminder Due',
      );
    });

    test('status is Due Soon', () {
      final DateTime expiry = DateTime(2026, 9, 20);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Due Soon',
      );
    });

    test('status is Active after 30 days', () {
      final DateTime expiry = DateTime(2026, 10, 4);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Active',
      );
    });

    test('exactly 30 days is a reminder', () {
      final DateTime expiry = DateTime(2026, 10, 3);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Reminder Due',
      );
    });

    test('exactly 15 days is a reminder', () {
      final DateTime expiry = DateTime(2026, 9, 18);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Reminder Due',
      );
    });

    test('exactly 7 days is a reminder', () {
      final DateTime expiry = DateTime(2026, 9, 10);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Reminder Due',
      );
    });

    test('exactly 1 day is a reminder', () {
      final DateTime expiry = DateTime(2026, 9, 4);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Reminder Due',
      );
    });

    test('8 days is Due Soon but not a scheduled reminder', () {
      final DateTime expiry = DateTime(2026, 9, 11);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Due Soon',
      );

      expect(
        CarDocumentReminderService.isReminderDue(
          expiry,
          today: today,
        ),
        isFalse,
      );
    });

    test('31 days is Active and has no active reminder', () {
      final DateTime expiry = DateTime(2026, 10, 4);

      expect(
        CarDocumentReminderService.getStatus(
          expiry,
          today: today,
        ),
        'Active',
      );

      expect(
        CarDocumentReminderService.hasActiveReminder(
          expiry,
          today: today,
        ),
        isFalse,
      );
    });

    test('reminder day list contains the four required days', () {
      expect(
        CarDocumentReminderService.reminderDays,
        equals(<int>[30, 15, 7, 1]),
      );
    });
  });
}
