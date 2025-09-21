;; Influencer Marketing Platform Smart Contract
;; A comprehensive platform for managing influencer campaigns, payments, and reputation

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-CAMPAIGN-EXPIRED (err u103))
(define-constant ERR-ALREADY-APPLIED (err u104))
(define-constant ERR-NOT-SELECTED (err u105))
(define-constant ERR-WORK-NOT-SUBMITTED (err u106))
(define-constant ERR-ALREADY-COMPLETED (err u107))
(define-constant ERR-INSUFFICIENT-FUNDS (err u108))
(define-constant ERR-INVALID-RATING (err u109))
(define-constant ERR-INVALID-INPUT (err u110))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Campaign status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-COMPLETED u2)
(define-constant STATUS-CANCELLED u3)

;; Input validation constants
(define-constant MAX-ENGAGEMENT-RATE u10000) ;; 100% in basis points
(define-constant MAX-FOLLOWER-COUNT u1000000000) ;; 1 billion max
(define-constant MIN-CAMPAIGN-DURATION u144) ;; ~1 day in blocks

;; Data structures
(define-map campaigns
  { campaign-id: uint }
  {
    brand: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    budget: uint,
    deadline: uint,
    requirements: (string-ascii 200),
    status: uint,
    selected-influencer: (optional principal),
    work-submitted: bool,
    work-approved: bool
  }
)

(define-map campaign-applications
  { campaign-id: uint, influencer: principal }
  {
    proposal: (string-ascii 300),
    requested-amount: uint,
    applied-at: uint
  }
)

(define-map influencer-profiles
  { influencer: principal }
  {
    name: (string-ascii 50),
    bio: (string-ascii 200),
    social-handles: (string-ascii 100),
    follower-count: uint,
    engagement-rate: uint,
    total-campaigns: uint,
    average-rating: uint,
    is-verified: bool
  }
)

(define-map brand-profiles
  { brand: principal }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    website: (string-ascii 100),
    total-campaigns: uint,
    total-spent: uint
  }
)

(define-map campaign-ratings
  { campaign-id: uint }
  { brand-rating: uint, influencer-rating: uint }
)

(define-map escrow-funds
  { campaign-id: uint }
  { amount: uint, released: bool }
)

;; Data variables
(define-data-var campaign-counter uint u0)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points

;; Platform fee wallet
(define-data-var fee-wallet principal CONTRACT-OWNER)

;; Input validation helpers
(define-private (is-valid-string (input (string-ascii 500)))
  (> (len input) u0)
)

(define-private (is-valid-engagement-rate (rate uint))
  (and (>= rate u0) (<= rate MAX-ENGAGEMENT-RATE))
)

(define-private (is-valid-follower-count (count uint))
  (<= count MAX-FOLLOWER-COUNT)
)

(define-private (is-valid-campaign-id (id uint))
  (and (> id u0) (<= id (var-get campaign-counter)))
)

;; Read-only functions
(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-influencer-profile (influencer principal))
  (map-get? influencer-profiles { influencer: influencer })
)

(define-read-only (get-brand-profile (brand principal))
  (map-get? brand-profiles { brand: brand })
)

(define-read-only (get-campaign-application (campaign-id uint) (influencer principal))
  (map-get? campaign-applications { campaign-id: campaign-id, influencer: influencer })
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

;; Public functions

;; Create influencer profile
(define-public (create-influencer-profile (name (string-ascii 50)) (bio (string-ascii 200)) 
                                        (social-handles (string-ascii 100)) (follower-count uint) (engagement-rate uint))
  (let
    (
      (validated-name (if (is-valid-string name) name "Anonymous"))
      (validated-bio (if (is-valid-string bio) bio "No bio provided"))
      (validated-handles (if (is-valid-string social-handles) social-handles "Not provided"))
      (validated-followers (if (is-valid-follower-count follower-count) follower-count u0))
      (validated-engagement (if (is-valid-engagement-rate engagement-rate) engagement-rate u0))
    )
    (map-set influencer-profiles
      { influencer: tx-sender }
      {
        name: validated-name,
        bio: validated-bio,
        social-handles: validated-handles,
        follower-count: validated-followers,
        engagement-rate: validated-engagement,
        total-campaigns: u0,
        average-rating: u0,
        is-verified: false
      }
    )
    (ok true)
  )
)

;; Create brand profile
(define-public (create-brand-profile (name (string-ascii 50)) (description (string-ascii 200)) (website (string-ascii 100)))
  (let
    (
      (validated-name (if (is-valid-string name) name "Anonymous Brand"))
      (validated-desc (if (is-valid-string description) description "No description"))
      (validated-website (if (is-valid-string website) website "Not provided"))
    )
    (map-set brand-profiles
      { brand: tx-sender }
      {
        name: validated-name,
        description: validated-desc,
        website: validated-website,
        total-campaigns: u0,
        total-spent: u0
      }
    )
    (ok true)
  )
)

;; Create campaign
(define-public (create-campaign (title (string-ascii 100)) (description (string-ascii 500)) 
                              (budget uint) (deadline uint) (requirements (string-ascii 200)))
  (let
    (
      (campaign-id (+ (var-get campaign-counter) u1))
      (platform-fee (calculate-platform-fee budget))
      (total-amount (+ budget platform-fee))
      (validated-title (if (is-valid-string title) title "Untitled Campaign"))
      (validated-desc (if (is-valid-string description) description "No description"))
      (validated-req (if (is-valid-string requirements) requirements "No specific requirements"))
    )
    (asserts! (> budget u0) ERR-INVALID-AMOUNT)
    (asserts! (> deadline (+ block-height MIN-CAMPAIGN-DURATION)) ERR-CAMPAIGN-EXPIRED)
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      {
        brand: tx-sender,
        title: validated-title,
        description: validated-desc,
        budget: budget,
        deadline: deadline,
        requirements: validated-req,
        status: STATUS-ACTIVE,
        selected-influencer: none,
        work-submitted: false,
        work-approved: false
      }
    )
    
    (map-set escrow-funds
      { campaign-id: campaign-id }
      { amount: budget, released: false }
    )
    
    (var-set campaign-counter campaign-id)
    
    ;; Update brand profile
    (match (map-get? brand-profiles { brand: tx-sender })
      profile (map-set brand-profiles
                { brand: tx-sender }
                (merge profile { total-campaigns: (+ (get total-campaigns profile) u1) }))
      true
    )
    
    (ok campaign-id)
  )
)

;; Apply to campaign
(define-public (apply-to-campaign (campaign-id uint) (proposal (string-ascii 300)) (requested-amount uint))
  (let
    (
      (validated-id (asserts! (is-valid-campaign-id campaign-id) ERR-INVALID-INPUT))
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (validated-proposal (if (is-valid-string proposal) proposal "No proposal provided"))
    )
    (asserts! (is-eq (get status campaign) STATUS-ACTIVE) ERR-CAMPAIGN-EXPIRED)
    (asserts! (< block-height (get deadline campaign)) ERR-CAMPAIGN-EXPIRED)
    (asserts! (<= requested-amount (get budget campaign)) ERR-INVALID-AMOUNT)
    (asserts! (> requested-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? campaign-applications { campaign-id: campaign-id, influencer: tx-sender })) ERR-ALREADY-APPLIED)
    
    (map-set campaign-applications
      { campaign-id: campaign-id, influencer: tx-sender }
      {
        proposal: validated-proposal,
        requested-amount: requested-amount,
        applied-at: block-height
      }
    )
    
    (ok true)
  )
)

;; Select influencer for campaign
(define-public (select-influencer (campaign-id uint) (influencer principal))
  (let
    (
      (validated-id (asserts! (is-valid-campaign-id campaign-id) ERR-INVALID-INPUT))
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (application (unwrap! (map-get? campaign-applications { campaign-id: campaign-id, influencer: influencer }) ERR-NOT-SELECTED))
    )
    (asserts! (is-eq (get brand campaign) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status campaign) STATUS-ACTIVE) ERR-CAMPAIGN-EXPIRED)
    
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { selected-influencer: (some influencer) })
    )
    
    (ok true)
  )
)

;; Submit work
(define-public (submit-work (campaign-id uint))
  (let
    (
      (validated-id (asserts! (is-valid-campaign-id campaign-id) ERR-INVALID-INPUT))
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
    )
    (asserts! (is-eq (some tx-sender) (get selected-influencer campaign)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status campaign) STATUS-ACTIVE) ERR-CAMPAIGN-EXPIRED)
    
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { work-submitted: true })
    )
    
    (ok true)
  )
)

;; Approve work and release payment
(define-public (approve-work (campaign-id uint))
  (let
    (
      (validated-id (asserts! (is-valid-campaign-id campaign-id) ERR-INVALID-INPUT))
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (escrow (unwrap! (map-get? escrow-funds { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (influencer (unwrap! (get selected-influencer campaign) ERR-NOT-SELECTED))
      (application (unwrap! (map-get? campaign-applications { campaign-id: campaign-id, influencer: influencer }) ERR-NOT-SELECTED))
    )
    (asserts! (is-eq (get brand campaign) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get work-submitted campaign) ERR-WORK-NOT-SUBMITTED)
    (asserts! (not (get work-approved campaign)) ERR-ALREADY-COMPLETED)
    (asserts! (not (get released escrow)) ERR-ALREADY-COMPLETED)
    
    ;; Release payment to influencer
    (try! (as-contract (stx-transfer? (get requested-amount application) tx-sender influencer)))
    
    ;; Update campaign status
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { work-approved: true, status: STATUS-COMPLETED })
    )
    
    ;; Mark escrow as released
    (map-set escrow-funds
      { campaign-id: campaign-id }
      (merge escrow { released: true })
    )
    
    ;; Update influencer profile
    (match (map-get? influencer-profiles { influencer: influencer })
      profile (map-set influencer-profiles
                { influencer: influencer }
                (merge profile { total-campaigns: (+ (get total-campaigns profile) u1) }))
      true
    )
    
    ;; Update brand profile
    (match (map-get? brand-profiles { brand: tx-sender })
      profile (map-set brand-profiles
                { brand: tx-sender }
                (merge profile { total-spent: (+ (get total-spent profile) (get requested-amount application)) }))
      true
    )
    
    (ok true)
  )
)

;; Rate campaign participants
(define-public (rate-campaign (campaign-id uint) (brand-rating uint) (influencer-rating uint))
  (let
    (
      (validated-id (asserts! (is-valid-campaign-id campaign-id) ERR-INVALID-INPUT))
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
    )
    (asserts! (and (<= brand-rating u5) (>= brand-rating u1)) ERR-INVALID-RATING)
    (asserts! (and (<= influencer-rating u5) (>= influencer-rating u1)) ERR-INVALID-RATING)
    (asserts! (is-eq (get status campaign) STATUS-COMPLETED) ERR-CAMPAIGN-NOT-FOUND)
    (asserts! (or (is-eq (get brand campaign) tx-sender) 
                  (is-eq (some tx-sender) (get selected-influencer campaign))) ERR-NOT-AUTHORIZED)
    
    (map-set campaign-ratings
      { campaign-id: campaign-id }
      { brand-rating: brand-rating, influencer-rating: influencer-rating }
    )
    
    (ok true)
  )
)

;; Cancel campaign (emergency function)
(define-public (cancel-campaign (campaign-id uint))
  (let
    (
      (validated-id (asserts! (is-valid-campaign-id campaign-id) ERR-INVALID-INPUT))
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (escrow (unwrap! (map-get? escrow-funds { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
    )
    (asserts! (is-eq (get brand campaign) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get work-approved campaign)) ERR-ALREADY-COMPLETED)
    (asserts! (not (get released escrow)) ERR-ALREADY-COMPLETED)
    
    ;; Refund to brand (minus platform fee)
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get brand campaign))))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { status: STATUS-CANCELLED })
    )
    
    (map-set escrow-funds
      { campaign-id: campaign-id }
      (merge escrow { released: true })
    )
    
    (ok true)
  )
)

;; Admin function to verify influencer
(define-public (verify-influencer (influencer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq influencer tx-sender)) ERR-INVALID-INPUT) ;; Validate principal
    (match (map-get? influencer-profiles { influencer: influencer })
      profile (begin
        (map-set influencer-profiles
          { influencer: influencer }
          (merge profile { is-verified: true }))
        (ok true))
      ERR-CAMPAIGN-NOT-FOUND
    )
  )
)

;; Admin function to collect platform fees
(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (as-contract (stx-transfer? amount tx-sender (var-get fee-wallet))))
    (ok true)
  )
)