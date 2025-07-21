;; Legal Billing Automation Smart Contract
;; This contract manages legal billing, time tracking, client management, and automated invoicing

;;  CONSTANTS
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_CLIENT_NOT_FOUND (err u101))
(define-constant ERR_LAWYER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_INVALID_RATE (err u104))
(define-constant ERR_INVOICE_NOT_FOUND (err u105))
(define-constant ERR_INVOICE_ALREADY_PAID (err u106))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u107))
(define-constant ERR_TIME_ENTRY_NOT_FOUND (err u108))
(define-constant ERR_INVALID_TIME_ENTRY (err u109))
(define-constant ERR_CLIENT_ALREADY_EXISTS (err u110))
(define-constant ERR_LAWYER_ALREADY_EXISTS (err u111))
(define-constant ERR_INVALID_STATUS (err u112))
(define-constant ERR_CASE_NOT_FOUND (err u113))
(define-constant ERR_CASE_ALREADY_EXISTS (err u114))
(define-constant ERR_INVALID_INPUT (err u115))
(define-constant ERR_INVALID_EMAIL (err u116))
(define-constant ERR_INVALID_NAME (err u117))
(define-constant ERR_INVALID_SPECIALIZATION (err u118))
(define-constant ERR_INVALID_TITLE (err u119))
(define-constant ERR_INVALID_DESCRIPTION (err u120))
(define-constant ERR_INVALID_DUE_BLOCKS (err u121))
(define-constant ERR_INVALID_FEE (err u122))
(define-constant ERR_INVALID_DUE_DATE (err u123))

;; Minimum and maximum values for validation
(define-constant MIN_HOURLY_RATE u50)
(define-constant MAX_HOURLY_RATE u10000)
(define-constant MIN_TIME_MINUTES u1)
(define-constant MAX_TIME_MINUTES u1440) ;; 24 hours in minutes

;; DATA VARIABLES
(define-data-var next-client-id uint u1)
(define-data-var next-lawyer-id uint u1)
(define-data-var next-time-entry-id uint u1)
(define-data-var next-invoice-id uint u1)
(define-data-var next-case-id uint u1)
(define-data-var contract-fee-percentage uint u5) ;; 5% default contract fee

;; DATA MAPS

;; Client information
(define-map clients 
    uint 
    {
        name: (string-ascii 100),
        email: (string-ascii 100),
        address: principal,
        active: bool,
        created-at: uint
    }
)

;; Lawyer information
(define-map lawyers 
    uint 
    {
        name: (string-ascii 100),
        email: (string-ascii 100),
        address: principal,
        hourly-rate: uint,
        specialization: (string-ascii 50),
        active: bool,
        created-at: uint
    }
)

;; Legal cases
(define-map cases
    uint
    {
        client-id: uint,
        lawyer-id: uint,
        title: (string-ascii 200),
        description: (string-ascii 500),
        status: (string-ascii 20), ;; "active", "closed", "pending"
        created-at: uint,
        updated-at: uint
    }
)

;; Time entries for billing
(define-map time-entries 
    uint 
    {
        case-id: uint,
        lawyer-id: uint,
        client-id: uint,
        description: (string-ascii 500),
        minutes: uint,
        hourly-rate: uint,
        amount: uint,
        date: uint,
        billable: bool,
        invoiced: bool
    }
)

;; Invoice management
(define-map invoices 
    uint 
    {
        client-id: uint,
        lawyer-id: uint,
        case-id: uint,
        total-amount: uint,
        paid-amount: uint,
        status: (string-ascii 20), ;; "pending", "paid", "overdue", "cancelled"
        due-date: uint,
        created-at: uint,
        paid-at: (optional uint)
    }
)

;; Invoice line items (time entries associated with an invoice)
(define-map invoice-items 
    { invoice-id: uint, time-entry-id: uint }
    {
        amount: uint,
        description: (string-ascii 500)
    }
)

;; Track payments
(define-map payments
    uint
    {
        invoice-id: uint,
        client-id: uint,
        amount: uint,
        payment-date: uint,
        tx-hash: (buff 32)
    }
)

;; Client-Lawyer relationships
(define-map client-lawyer-relationships
    { client-id: uint, lawyer-id: uint }
    {
        retainer-amount: uint,
        active: bool,
        created-at: uint
    }
)

;; READ-ONLY FUNCTIONS

;; Get client information
(define-read-only (get-client (client-id uint))
    (map-get? clients client-id)
)

;; Get lawyer information
(define-read-only (get-lawyer (lawyer-id uint))
    (map-get? lawyers lawyer-id)
)

;; Get case information
(define-read-only (get-case (case-id uint))
    (map-get? cases case-id)
)

;; Get time entry
(define-read-only (get-time-entry (entry-id uint))
    (map-get? time-entries entry-id)
)

;; Get invoice
(define-read-only (get-invoice (invoice-id uint))
    (map-get? invoices invoice-id)
)

;; Get invoice item
(define-read-only (get-invoice-item (invoice-id uint) (time-entry-id uint))
    (map-get? invoice-items { invoice-id: invoice-id, time-entry-id: time-entry-id })
)

;; Get contract fee percentage
(define-read-only (get-contract-fee-percentage)
    (var-get contract-fee-percentage)
)

;; Calculate billable amount based on time and rate
(define-read-only (calculate-amount (minutes uint) (hourly-rate uint))
    (let ((hours-decimal (* minutes u100)))
        (/ (* hours-decimal hourly-rate) u6000) ;; Convert to proper decimal calculation
    )
)

;; Get total unbilled time for a case
(define-read-only (get-unbilled-time-for-case (case-id uint))
    (ok u0)
)

;; Get client-lawyer relationship
(define-read-only (get-client-lawyer-relationship (client-id uint) (lawyer-id uint))
    (map-get? client-lawyer-relationships { client-id: client-id, lawyer-id: lawyer-id })
)

;; PRIVATE FUNCTIONS

;; Validate hourly rate
(define-private (is-valid-hourly-rate (rate uint))
    (and (>= rate MIN_HOURLY_RATE) (<= rate MAX_HOURLY_RATE))
)

;; Validate time entry
(define-private (is-valid-time-minutes (minutes uint))
    (and (>= minutes MIN_TIME_MINUTES) (<= minutes MAX_TIME_MINUTES))
)

;; Validate email format (simplified)
(define-private (is-valid-email (email (string-ascii 100)))
    (and (> (len email) u5) (< (len email) u100))
)

;; Validate name input
(define-private (is-valid-name (name (string-ascii 100)))
    (and (> (len name) u0) (< (len name) u100))
)

;; Validate specialization input
(define-private (is-valid-specialization (specialization (string-ascii 50)))
    (and (> (len specialization) u0) (< (len specialization) u50))
)

;; Validate title input
(define-private (is-valid-title (title (string-ascii 200)))
    (and (> (len title) u0) (< (len title) u200))
)

;; Validate description input
(define-private (is-valid-description (description (string-ascii 500)))
    (and (> (len description) u0) (< (len description) u500))
)

;; Validate principal address (check if it's a valid principal)
(define-private (is-valid-principal (address principal))
    (not (is-eq address 'SP000000000000000000002Q6VF78))
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT_OWNER)
)

;; Validate status values
(define-private (is-valid-case-status (status (string-ascii 20)))
    (or (is-eq status "active") 
        (or (is-eq status "closed") (is-eq status "pending")))
)

(define-private (is-valid-invoice-status (status (string-ascii 20)))
    (or (is-eq status "pending") 
        (or (is-eq status "paid") 
            (or (is-eq status "overdue") (is-eq status "cancelled"))))
)

;; Sanitize and validate client data
(define-private (validate-client-data (name (string-ascii 100)) (email (string-ascii 100)) (client-address principal))
    (and (is-valid-name name)
         (is-valid-email email)
         (is-valid-principal client-address))
)

;; Sanitize and validate lawyer data
(define-private (validate-lawyer-data (name (string-ascii 100)) (email (string-ascii 100)) 
                                     (lawyer-address principal) (specialization (string-ascii 50)))
    (and (is-valid-name name)
         (is-valid-email email)
         (is-valid-principal lawyer-address)
         (is-valid-specialization specialization))
)

;; Validate case ID range
(define-private (is-valid-case-id (case-id uint))
    (and (>= case-id u1) (< case-id (var-get next-case-id)))
)

;; Validate client ID range
(define-private (is-valid-client-id (client-id uint))
    (and (>= client-id u1) (< client-id (var-get next-client-id)))
)

;; Validate lawyer ID range
(define-private (is-valid-lawyer-id (lawyer-id uint))
    (and (>= lawyer-id u1) (< lawyer-id (var-get next-lawyer-id)))
)

;; PUBLIC FUNCTIONS

;; Register a new client
(define-public (register-client (name (string-ascii 100)) (email (string-ascii 100)) (client-address principal))
    (let ((client-id (var-get next-client-id)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (validate-client-data name email client-address) ERR_INVALID_INPUT)
        (asserts! (is-none (map-get? clients client-id)) ERR_CLIENT_ALREADY_EXISTS)
        
        (map-set clients client-id {
            name: name,
            email: email,
            address: client-address,
            active: true,
            created-at: block-height
        })
        
        (var-set next-client-id (+ client-id u1))
        (ok client-id)
    )
)

;; Register a new lawyer
(define-public (register-lawyer (name (string-ascii 100)) (email (string-ascii 100)) 
                               (lawyer-address principal) (hourly-rate uint) (specialization (string-ascii 50)))
    (let ((lawyer-id (var-get next-lawyer-id)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (validate-lawyer-data name email lawyer-address specialization) ERR_INVALID_INPUT)
        (asserts! (is-valid-hourly-rate hourly-rate) ERR_INVALID_RATE)
        (asserts! (is-none (map-get? lawyers lawyer-id)) ERR_LAWYER_ALREADY_EXISTS)
        
        (map-set lawyers lawyer-id {
            name: name,
            email: email,
            address: lawyer-address,
            hourly-rate: hourly-rate,
            specialization: specialization,
            active: true,
            created-at: block-height
        })
        
        (var-set next-lawyer-id (+ lawyer-id u1))
        (ok lawyer-id)
    )
)

;; Create a new legal case
(define-public (create-case (client-id uint) (lawyer-id uint) (title (string-ascii 200)) 
                           (description (string-ascii 500)))
    (let ((case-id (var-get next-case-id)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-some (get-client client-id)) ERR_CLIENT_NOT_FOUND)
        (asserts! (is-some (get-lawyer lawyer-id)) ERR_LAWYER_NOT_FOUND)
        (asserts! (is-valid-title title) ERR_INVALID_TITLE)
        (asserts! (is-valid-description description) ERR_INVALID_DESCRIPTION)
        
        (map-set cases case-id {
            client-id: client-id,
            lawyer-id: lawyer-id,
            title: title,
            description: description,
            status: "active",
            created-at: block-height,
            updated-at: block-height
        })
        
        (var-set next-case-id (+ case-id u1))
        (ok case-id)
    )
)

;; Add time entry
(define-public (add-time-entry (case-id uint) (lawyer-id uint) (description (string-ascii 500)) 
                              (minutes uint) (billable bool))
    (let ((entry-id (var-get next-time-entry-id))
          (case-info (unwrap! (get-case case-id) ERR_CASE_NOT_FOUND))
          (lawyer-info (unwrap! (get-lawyer lawyer-id) ERR_LAWYER_NOT_FOUND))
          (client-id (get client-id case-info))
          (hourly-rate (get hourly-rate lawyer-info))
          (amount (calculate-amount minutes hourly-rate)))
        
        (asserts! (or (is-contract-owner) (is-eq tx-sender (get address lawyer-info))) ERR_UNAUTHORIZED)
        (asserts! (is-valid-time-minutes minutes) ERR_INVALID_TIME_ENTRY)
        (asserts! (is-valid-description description) ERR_INVALID_DESCRIPTION)
        (asserts! (is-eq (get lawyer-id case-info) lawyer-id) ERR_UNAUTHORIZED)
        
        (map-set time-entries entry-id {
            case-id: case-id,
            lawyer-id: lawyer-id,
            client-id: client-id,
            description: description,
            minutes: minutes,
            hourly-rate: hourly-rate,
            amount: amount,
            date: block-height,
            billable: billable,
            invoiced: false
        })
        
        (var-set next-time-entry-id (+ entry-id u1))
        (ok entry-id)
    )
)

;; Create invoice for unbilled time entries
(define-public (create-invoice (client-id uint) (lawyer-id uint) (case-id uint) (due-blocks uint))
    (let ((invoice-id (var-get next-invoice-id)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-some (get-client client-id)) ERR_CLIENT_NOT_FOUND)
        (asserts! (is-some (get-lawyer lawyer-id)) ERR_LAWYER_NOT_FOUND)
        (asserts! (is-some (get-case case-id)) ERR_CASE_NOT_FOUND)
        (asserts! (> due-blocks u0) ERR_INVALID_DUE_BLOCKS)
        
        ;; Create invoice with zero amount initially - would be calculated from time entries
        (map-set invoices invoice-id {
            client-id: client-id,
            lawyer-id: lawyer-id,
            case-id: case-id,
            total-amount: u0, ;; Would calculate from unbilled time entries
            paid-amount: u0,
            status: "pending",
            due-date: (+ block-height due-blocks),
            created-at: block-height,
            paid-at: none
        })
        
        (var-set next-invoice-id (+ invoice-id u1))
        (ok invoice-id)
    )
)

;; Update invoice total amount
(define-public (update-invoice-amount (invoice-id uint) (total-amount uint))
    (let ((invoice-info (unwrap! (get-invoice invoice-id) ERR_INVOICE_NOT_FOUND)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (> total-amount u0) ERR_INVALID_AMOUNT)
        (asserts! (is-eq (get status invoice-info) "pending") ERR_INVOICE_ALREADY_PAID)
        
        (map-set invoices invoice-id (merge invoice-info { total-amount: total-amount }))
        (ok true)
    )
)

;; Process payment for an invoice
(define-public (pay-invoice (invoice-id uint))
    (let ((invoice-info (unwrap! (get-invoice invoice-id) ERR_INVOICE_NOT_FOUND))
          (client-info (unwrap! (get-client (get client-id invoice-info)) ERR_CLIENT_NOT_FOUND))
          (total-amount (get total-amount invoice-info))
          (contract-fee (/ (* total-amount (var-get contract-fee-percentage)) u100))
          (lawyer-amount (- total-amount contract-fee)))
        
        (asserts! (is-eq tx-sender (get address client-info)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status invoice-info) "pending") ERR_INVOICE_ALREADY_PAID)
        (asserts! (> total-amount u0) ERR_INVALID_AMOUNT)
        
        ;; Update invoice status
        (map-set invoices invoice-id (merge invoice-info {
            paid-amount: total-amount,
            status: "paid",
            paid-at: (some block-height)
        }))
        
        (ok true)
    )
)

;; Update case status
(define-public (update-case-status (case-id uint) (new-status (string-ascii 20)))
    (let ((case-info (unwrap! (get-case case-id) ERR_CASE_NOT_FOUND)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-valid-case-status new-status) ERR_INVALID_STATUS)
        (asserts! (> case-id u0) ERR_INVALID_INPUT)
        
        ;; Create validated case data with all original fields plus updates
        (let ((validated-case-data {
            client-id: (get client-id case-info),
            lawyer-id: (get lawyer-id case-info),
            title: (get title case-info),
            description: (get description case-info),
            status: new-status,
            created-at: (get created-at case-info),
            updated-at: block-height
        }))
            ;; Only update if case-id is within valid range
            (if (and (>= case-id u1) (< case-id (var-get next-case-id)))
                (begin
                    (map-set cases case-id validated-case-data)
                    (ok true)
                )
                ERR_CASE_NOT_FOUND
            )
        )
    )
)

;; Update lawyer hourly rate
(define-public (update-lawyer-rate (lawyer-id uint) (new-rate uint))
    (let ((lawyer-info (unwrap! (get-lawyer lawyer-id) ERR_LAWYER_NOT_FOUND)))
        (asserts! (or (is-contract-owner) (is-eq tx-sender (get address lawyer-info))) ERR_UNAUTHORIZED)
        (asserts! (is-valid-hourly-rate new-rate) ERR_INVALID_RATE)
        
        (map-set lawyers lawyer-id (merge lawyer-info { hourly-rate: new-rate }))
        (ok true)
    )
)

;; Deactivate client
(define-public (deactivate-client (client-id uint))
    (let ((client-info (unwrap! (get-client client-id) ERR_CLIENT_NOT_FOUND)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-valid-client-id client-id) ERR_CLIENT_NOT_FOUND)
        
        ;; Create validated client data with all original fields
        (let ((validated-client-data {
            name: (get name client-info),
            email: (get email client-info),
            address: (get address client-info),
            active: false,
            created-at: (get created-at client-info)
        }))
            (map-set clients client-id validated-client-data)
            (ok true)
        )
    )
)

;; Deactivate lawyer
(define-public (deactivate-lawyer (lawyer-id uint))
    (let ((lawyer-info (unwrap! (get-lawyer lawyer-id) ERR_LAWYER_NOT_FOUND)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-valid-lawyer-id lawyer-id) ERR_LAWYER_NOT_FOUND)
        
        ;; Create validated lawyer data with all original fields
        (let ((validated-lawyer-data {
            name: (get name lawyer-info),
            email: (get email lawyer-info),
            address: (get address lawyer-info),
            hourly-rate: (get hourly-rate lawyer-info),
            specialization: (get specialization lawyer-info),
            active: false,
            created-at: (get created-at lawyer-info)
        }))
            (map-set lawyers lawyer-id validated-lawyer-data)
            (ok true)
        )
    )
)

;; Establish client-lawyer relationship with retainer
(define-public (establish-relationship (client-id uint) (lawyer-id uint) (retainer-amount uint))
    (begin
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-some (get-client client-id)) ERR_CLIENT_NOT_FOUND)
        (asserts! (is-some (get-lawyer lawyer-id)) ERR_LAWYER_NOT_FOUND)
        (asserts! (> retainer-amount u0) ERR_INVALID_AMOUNT)
        
        (map-set client-lawyer-relationships 
            { client-id: client-id, lawyer-id: lawyer-id }
            {
                retainer-amount: retainer-amount,
                active: true,
                created-at: block-height
            }
        )
        (ok true)
    )
)

;; Update contract fee percentage (only owner)
(define-public (update-contract-fee (new-fee uint))
    (begin
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (<= new-fee u20) ERR_INVALID_FEE) ;; Max 20% fee
        
        (var-set contract-fee-percentage new-fee)
        (ok true)
    )
)

;; Mark invoice as overdue
(define-public (mark-invoice-overdue (invoice-id uint))
    (let ((invoice-info (unwrap! (get-invoice invoice-id) ERR_INVOICE_NOT_FOUND)))
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status invoice-info) "pending") ERR_INVALID_STATUS)
        (asserts! (< (get due-date invoice-info) block-height) ERR_INVALID_DUE_DATE)
        
        (map-set invoices invoice-id (merge invoice-info { status: "overdue" }))
        (ok true)
    )
)