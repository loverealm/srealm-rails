Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'dj.log'))
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.raise_signal_exceptions = :term
