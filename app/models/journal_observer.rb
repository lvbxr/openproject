class JournalObserver < ActiveRecord::Observer
  attr_accessor :send_notification

  def after_create(journal)
    if journal.type == "IssueJournal" and journal.version > 1 and self.send_notification
      after_create_issue_journal(journal)
    end
    clear_notification
  end

  def after_create_issue_journal(journal)
    if Setting.notified_events.include?('issue_updated') ||
        (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
        (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
        (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
      Mailer.deliver_issue_edit(journal)
    end
  end

  # Wrap send_notification so it defaults to true, when it's nil
  def send_notification
    return true if @send_notification.nil?
    return @send_notification
  end
  
  private

  # Need to clear the notification setting after each usage otherwise it might be cached
  def clear_notification
    @send_notification = true
  end

end
