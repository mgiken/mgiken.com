(require "markdown.arc")
(require "sh.arc")
(require "conf.arc")

(def git-clone ()
  (unless dir-exists.gitpath*
    (system:+ "git clone" (escshargs gitrepo* gitpath*))))

(def git-pull ()
  (system:+ "cd" escshargs.gitpath* ";git pull"))

(def update-posts (posts index)
  (= posts* posts
     index* index))

(def load-post (dt path)
  (w/stdin infile.path
    (obj id     (datestring dt "~Y/~m/~d/~H~M~S")
         pubat  (datestring dt "~4")
         title  (readline)
         auther (readline)
         tags   (sort < (tokens:readline))
         sep    (readline)
         body   (markdown:tostring:whiler x (readline) nil (prn x)))))

(def load-posts ()
  (let posts (table)
    (w/dir name path gitpath*
      (unless (headmatch "." name)
        (let post (load-post int.name path)
          (= (posts post!id) post))))
    (update-posts posts (sort > keys.posts))))

(def refresh ()
  (git-clone)
  (git-pull)
  (load-posts))

; tags -----------------------------------------------------------------------

(deflayout basepage "松村技研"
  `((<sitename name "松村技研"))
  `((<copyright url "http://mgiken.com/" owner "MATSUMURA GIKEN")))

(deftag pubdate
  `(let x ,car.children
     (<time pubdate "pubdate" datetime x x)))

(deftag tags
  `(<ul (each x ,car.children
     (<li x))))

(deftag post
  `(let p ,car.children
     (<article class "post"
       (<header
         (<h1 (<a href (+ "/blog/" p!id) p!title))
         (<ul class "meta"
           (<li class "auther"  (<span    p!auther))
           (<li class "pubdate" (<pubdate p!pubat))
           (<li class "tags"    (<tags    p!tags))))
       (<div (raw p!body)))))

(deftag posts
  `(<div id "posts"
     (each i ,car.children
       (<post posts*.i))))

; pages ----------------------------------------------------------------------

; TODO
(defp /
  (redirect "/blog"))

(defp /blog
  (<basepage title "Blog"
    (<posts index*)))

(defp "/blog/(\\d{4}/\\d{2}/\\d{2}/\\d{6})"
  (aif (posts* request!pargs.0)
       (<basepage title it!title
         (<post it))
       (httperr 404)))

; GitHub Post-Receive Hook
(defp /refresh
  (when (is arg!key hookkey*)
    (thread (refresh))))

; load posts -----------------------------------------------------------------

(refresh)
