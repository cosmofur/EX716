
(defun my-shell-debug-linemove (output)
  "Monitor shell output and move the passive cursor based on a pattern."
  (interactive "e")
  (when (string-match ".*? # \\([^:]+\\):\\([0-9]+\\)" output)
    (let ((other-buffer-name (match-string 1 output))
          (line-number (string-to-number (match-string 2 output))))
      (when (get-buffer other-buffer-name)
        (let ((buffer (get-buffer other-buffer-name)))
          (unless (get-buffer-window buffer)
            (display-buffer buffer))
          (with-selected-window (get-buffer-window buffer)
            (let ((inhibit-read-only t))
              (goto-char (point-min))
              (forward-line (1- line-number))
              )
            )
          )
                ))))

(defun my-comint-watch-shell-output ()
  "Add a process filter to watch for shell output patterns."
  (let ((proc (get-buffer-process (current-buffer))))
    (when proc
      (set-process-filter
       proc
       (lambda (process output)
         ;; Call the default comint filter to display output in the buffer
         (comint-output-filter process output)
         ;; Call your custom function to handle the output
         (my-shell-debug-linemove output))))))
         
