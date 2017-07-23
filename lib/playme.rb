require 'rb_thread_pool'

a = catch :h do
  catch :b do
    [:h, 1]
  end
end
