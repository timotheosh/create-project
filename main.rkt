#lang racket/base

(module+ test
  (require rackunit))

;; Copyright Tim Hawes 2018
;; MIT License
;;
;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>
;;
;; See the current version of the racket style guide here:
;; http://docs.racket-lang.org/style/index.html

;; Code here
(require yaml)
;;(require "create-project.rkt")


(module+ test
  ;; Tests to be run with raco test
  )

(define configfile
  (make-parameter
   (file->yaml "/usr/local/etc/create-project.yaml")))

(define supported-languages
  (make-parameter
   (hash
    "c" "C language CMake Project"
    "cpp" "C++ language CMake project")))

(define supported-projects
  (make-parameter
   (hash
    "executable" "Executable program"
    "shared" "Shared Library"
    "static" "Static Library")))

(define (prompt-languages lang)
  (if (member lang (hash-keys (supported-languages)))
      lang
      (begin
        (for ([l (hash-keys (supported-languages))])
          (displayln (format "\t~a)\t~a" l (hash-ref (supported-languages) l))))
        (display "Which programming language for your project? ")
        (prompt-languages (read-line)))))

(define (prompt-project-types type)
  (if (member type (hash-keys (supported-projects)))
      type
      (begin
        (for ([t (hash-keys (supported-projects))])
          (displayln (format "\t~a)\t~a" t (hash-ref (supported-projects) t))))
        (display "Which project type for your project? ")
        (prompt-project-types (read-line)))))

(define (prompt-project-name-directory directory project-name)
  (let ([path (string-append directory project-name)])
    (if (not (directory-exists? path))
        path
        (begin
          (displayln (format "Directory ~a already exists!" path))
          (display "Change name of project directory? (Ctl-C to exit) ")
          (prompt-project-name-directory directory (read-line))))))

(module+ main
  ;; Main entry point, executed when run with the `racket` executable or DrRacket.
  (require racket)
  (require racket/cmdline)
  (require "cmake/cmake-project.rkt")

  (define project-type (make-parameter null))
  (define project-lang (make-parameter null))
  (define project-dir (make-parameter null))
  (define project-path (make-parameter null))
  (define project-name
    (command-line
     #:program "create-project"
     #:once-each
     [("-l" "--lang")        lang
                             "Name of the programming language to be used"
                             (project-lang lang)]
     [("-t" "--type")        type
                             "Type of project to create"
                             (project-type type)]
     [("-d" "--project-dir") directory
                             "Directory where project should be created"
                             (project-dir directory)]
     #:args (name)
     name))
  (project-lang (prompt-languages (project-lang)))
  (project-type (prompt-project-types (project-type)))
  (when (null? (project-dir))
    (if (hash-has-key? (configfile) "project-dir")
        (project-dir (hash-ref (configfile) "project-dir"))
        (project-dir (path->string (current-directory-for-user)))))
  (when (not (char=?
              (string-ref (project-dir) (sub1 (string-length (project-dir))))
              #\/))
    (project-dir (string-append (project-dir) "/")))
  (project-path (prompt-project-name-directory (project-dir) project-name))
  (create-cmake-project project-name (project-path) (project-lang) (project-type)))
