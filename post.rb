class Post

    @@count =-1
    @@instances = []
    attr_accessor :desc
    attr_reader :title

    def initialize(title,desc)
        @desc=desc
        @title=desc[:instance_id]
        @desc[:time]=(Time.now).inspect
        @desc[:bindings]={}
        @@count +=1
        @c=@@count
        @@instances << self
    end
    def Post.all()
        @@instances
    end

    def Post.bind(id,bid,bdat)
        @@instances.each do|el|
            if el.title===id
                el.desc[:bindings][:"#{bid}"]=bdat
                return true
            end
        end
        return false
    end

    def Post.unbind(id,bid)
        @@instances.each do|el|
            if el.title===id
                el.desc[:bindings]=el.desc[:bindings].reject!{|k,v| k == :"#{bid}"}
                return true
            end
        end
        return false
    end

    def Post.deinitialize(id)
        @@instances.each do|el|
            if el.title===id
                @@instances -=[el]
                return true
            end
        end
        return false
    end

end