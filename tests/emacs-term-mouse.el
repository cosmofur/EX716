(defun my-term-send-sgr-mouse (event pressed)
  "Send EVENT to the term subprocess using xterm SGR mouse format.

PRESSED is non-nil for a button press and nil for release."
  (interactive "e")

  (let* ((start  (event-start event))
         (window (posn-window start))
         (xy     (posn-x-y start))
         (col    (1+ (car xy)))       ; xterm coordinates are 1-based
         (row    (1+ (cdr xy)))
         (basic  (event-basic-type event))
         (mods   (event-modifiers event))

         ;; SGR button numbering:
         ;;   0 = left, 1 = middle, 2 = right
         (button
          (pcase basic
            ((or 'down-mouse-1 'mouse-1) 0)
            ((or 'down-mouse-2 'mouse-2) 1)
            ((or 'down-mouse-3 'mouse-3) 2)
            (_ 0))))

    ;; Modifier bits used by xterm mouse reporting.
    (when (memq 'shift mods)
      (setq button (+ button 4)))
    (when (memq 'meta mods)
      (setq button (+ button 8)))
    (when (memq 'control mods)
      (setq button (+ button 16)))

    ;; Ignore clicks outside the text portion of this term window.
    (when (and (windowp window)
               (eq (window-buffer window) (current-buffer))
               (process-live-p (get-buffer-process (current-buffer))))
      (process-send-string
       (get-buffer-process (current-buffer))
       (format "\e[<%d;%d;%d%s"
               button col row
               (if pressed "M" "m"))))))

(defun my-term-mouse-down (event)
  (interactive "e")
  (my-term-send-sgr-mouse event t))

(defun my-term-mouse-up (event)
  (interactive "e")
  (my-term-send-sgr-mouse event nil))

(with-eval-after-load 'term
  (define-key term-raw-map [down-mouse-1] #'my-term-mouse-down)
  (define-key term-raw-map [mouse-1]      #'my-term-mouse-up)

  (define-key term-raw-map [down-mouse-2] #'my-term-mouse-down)
  (define-key term-raw-map [mouse-2]      #'my-term-mouse-up)

  (define-key term-raw-map [down-mouse-3] #'my-term-mouse-down)
  (define-key term-raw-map [mouse-3]      #'my-term-mouse-up))
