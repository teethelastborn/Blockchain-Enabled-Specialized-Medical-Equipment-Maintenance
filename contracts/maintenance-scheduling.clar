;; Maintenance Scheduling Contract
;; Manages regular service and calibration

(define-data-var last-maintenance-id uint u0)

(define-map maintenance-tasks
  { id: uint }
  {
    device-id: uint,
    task-type: (string-ascii 50), ;; "routine", "repair", "calibration"
    description: (string-ascii 200),
    scheduled-date: uint,
    completed-date: (optional uint),
    technician: principal,
    status: (string-ascii 20), ;; "scheduled", "completed", "cancelled"
    created-by: principal
  }
)

;; Schedule maintenance task
(define-public (schedule-maintenance
    (device-id uint)
    (task-type (string-ascii 50))
    (description (string-ascii 200))
    (scheduled-date uint)
    (technician principal)
  )
  (let
    (
      (new-id (+ (var-get last-maintenance-id) u1))
    )
    ;; Update maintenance ID counter
    (var-set last-maintenance-id new-id)

    ;; Store maintenance task
    (map-set maintenance-tasks
      { id: new-id }
      {
        device-id: device-id,
        task-type: task-type,
        description: description,
        scheduled-date: scheduled-date,
        completed-date: none,
        technician: technician,
        status: "scheduled",
        created-by: tx-sender
      }
    )

    (ok new-id)
  )
)

;; Complete maintenance task
(define-public (complete-maintenance
    (maintenance-id uint)
  )
  (let
    (
      (task (unwrap! (map-get? maintenance-tasks { id: maintenance-id }) (err u404)))
    )
    ;; Check if caller is the assigned technician
    (asserts! (is-eq tx-sender (get technician task)) (err u403))

    ;; Check if task is in scheduled status
    (asserts! (is-eq (get status task) "scheduled") (err u400))

    ;; Update task status
    (map-set maintenance-tasks
      { id: maintenance-id }
      (merge task {
        status: "completed",
        completed-date: (some block-height)
      })
    )

    (ok true)
  )
)

;; Cancel maintenance task
(define-public (cancel-maintenance
    (maintenance-id uint)
  )
  (let
    (
      (task (unwrap! (map-get? maintenance-tasks { id: maintenance-id }) (err u404)))
    )
    ;; Check if caller is the creator
    (asserts! (is-eq tx-sender (get created-by task)) (err u403))

    ;; Check if task is in scheduled status
    (asserts! (is-eq (get status task) "scheduled") (err u400))

    ;; Update task status
    (map-set maintenance-tasks
      { id: maintenance-id }
      (merge task { status: "cancelled" })
    )

    (ok true)
  )
)

;; Get maintenance task details
(define-read-only (get-maintenance-task (maintenance-id uint))
  (map-get? maintenance-tasks { id: maintenance-id })
)

;; Get total maintenance task count
(define-read-only (get-maintenance-count)
  (var-get last-maintenance-id)
)
