#lang racket

;; Copyright Tim Hawes 2018
;; MIT License

(provide create-cmake-project)

(require yaml)
(require rastache)

(define configfile (file->yaml "/home/thawes/programs/etc/create-project.yaml"))

(define year (let ([date (seconds->date (current-seconds))])
               (date-year date)))

(define fullname (hash-ref configfile "fullname"))

;; Location of templates for creating projects.
(define template-dir
  (let ([str (open-output-string)])
    (rast-compile/render
     (open-input-string (hash-ref configfile "template-dir"))
     `#hash{ (prefix . ,(hash-ref configfile "prefix")) }
     str)
    (get-output-string str)))

(define (write-template src dest params)
  (rast-compile/render
   (open-input-file src)
   params
   (open-output-file dest)))

(define (create-cmake-directories path)
  (for ([x '("tests/src" "tests/include" "src")])
    (make-directory* (format "~a/~a" path x))))

(define (write-cmakelists name path lang type)
  (write-template
   (format "~A/cmake/~A/~A/CMakeLists.txt.mustache" template-dir lang type)
   (format "~A/CMakeLists.txt" path)
   `#hash{ (name . ,name)
           (year . ,year)
           (fullname . ,fullname) })
  (write-template
   (format "~A/cmake/tests/CMakeLists.txt.mustache" template-dir)
   (format "~A/tests/CMakeLists.txt" path)
   `#hash{ (name . ,name)
           (year . ,year)
           (fullname . ,fullname) }))

(define (write-sources name path lang type)
  (write-template
   (format "~A/cmake/~A/~A/src/main.~A.mustache" template-dir lang type lang)
   (format "~A/src/main.~A" path lang)
   `#hash{ (name . ,name)
           (year . ,year)
           (fullname . ,fullname) })
  (write-template
   (format "~A/cmake/tests/src/tests.cpp.mustache" template-dir)
   (format "~A/tests/src/tests.cpp" path)
   `#hash{ (name . ,name)
           (year . ,year)
           (fullname . ,fullname) })
  (copy-file
   (format "~A/cmake/tests/include/catch.hpp" template-dir)
   (format "~A/tests/include/catch.hpp" path)))

(define (create-cmake-project name path lang type)
  (create-cmake-directories path)
  (write-cmakelists name path lang type)
  (write-sources name path lang type))
