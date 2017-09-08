module TestSelect

using FactCheck
using DataCubes

immutable Wrap{T}
  elem::T
end

facts("Select tests") do
  col1 = nalift(reshape(500:-1:1, 10, 50))
  col2 = nalift(reshape(1.0*(1:500), 10, 50))
  col3 = nalift(reshape(map(i->string("sym_",i), 1:500), 10, 50))
  col4 = nalift(hcat(rand(10,30), fill(:testsym, 10, 20)))
  axis1c1 = DictArray(k1=nalift(collect(101:110)), k2=nalift(collect(201:210)))
  axis1c2 = DictArray(r1=nalift(map(i->string("a_",i), 1:50)))
  d = DictArray(c1=col1, c2=col2, c3=col3, c4=col4)
  lar = LabeledArray(d, axis1=axis1c1, axis2=axis1c2)
  context("@select tests") do
    @fact @select(lar) === lar --> true
    context("aggregate tests") do
      @fact @select(lar,:c2,:c3).data --> pick(lar,[:c2,:c3])
      @fact @select(lar,c2=broadcast(*, _c2, 2),:c3).data --> @darr(c2=2*pick(lar,:c2),c3=pick(lar,:c3))
      @fact @select(lar,c2=broadcast(*, _c2, 2),:c3) --> @select(lar,c2=broadcast(*, _[:c2], 2),:c3)
      @fact @select(larr(a=[1,2,3],b=[4,5,6]), :a=>sum(_a), :b=>length(_b)) --> nalift(LDict(:a=>6,:b=>3))
      @fact @select(@darr(a=[1 2 3 NA]), s=sum(_a), where[broadcast(>=, _a,2.0)]) --> nalift(LDict(:s=>5))
      @fact @select(larr(a=[1 2 3;4 5 6]), :a) --> larr(a=[1 2 3;4 5 6])
      @fact_throws @select(larr(rand(3,4)), :a)
      @fact_throws @select(larr(rand(5,3)), a=_a)
    end
    context("condition tests") do
      @fact @select(lar, where[broadcast(<, 10, _c2) & broadcast(<, _c2, 25)]) --> begin
        base = @larr(c1=col1[1:10,2:3],c2=col2[1:10,2:3],c3=col3[1:10,2:3],c4=col4[1:10,2:3],axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        dcube.setna!(base, 5:10, 2)
        base
      end
      @fact @select(lar, c1=broadcast(*, _c1, 2), where[broadcast(<, 10, _c2) & broadcast(<, _c2, 25)]) --> begin
        base = @larr(c1=broadcast(*, 2, col1[1:10,2:3]),axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        dcube.setna!(base, 5:10, 2)
        base
      end
    end
    context("by tests") do
      @fact size(@select(lar, by[k1=_k2 - _c1,:r1], by[m1=broadcast(>, _k2, 205)])) --> (500,2)
      @fact size(@select(lar, by[k1=_k2 - _k1], by[m1=broadcast(>, _k2, 205)])) --> (1,2)
      @fact @select(lar, by[k1=_k2 - _k1], by[m1=broadcast(>, _k2, 205)], c1=sum(igna(_c1))) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f1 = fld -> sum(igna(fld))
      @fact @select(lar, by[k1=_k2 - _k1], by[m1=broadcast(>, _k2, 205)], c1=f1(_c1)) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f2 = d -> sum(igna(d[:c1]))
      @fact @select(lar, by[k1=_k2 - _k1], by[m1=broadcast(>, _k2, 205)], c1=f2(_)) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      @fact size(@select(lar, by[k1=_k2 - _c1,:r1], by[m1=broadcast(>, _k2, 205)], c1= broadcast(*, _c1, _c2), :c2)) --> (500,2)
      @fact @select(@larr(a=collect(1:100),b=enumeration(repmat(collect(1:10),10))), by[:b], :a=>sum(_a), where[broadcast(>, _a, 56)]) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
      @fact @select(@larr(a=collect(1:100),b=repmat(collect(1:10),10), c=repmat(collect(1:10),10)), by[:b,:c], :a=>sum(_a), where[broadcast(>, _a, 56)]) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6],c=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
      @fact @select(@larr(a=collect(1:100),b=enumeration(repmat(collect(1:10),10)), c=repmat(collect(1:10),10)), by[:b,:c], :a=>sum(_a), where[broadcast(>, _a, 56)]) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6],c=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
      @fact @select(@larr(a=collect(1:100),b=repmat(collect(1:10),10), c=enumeration(repmat(collect(1:10),10))), by[:b,:c], :a=>sum(_a), where[broadcast(>, _a, 56)]) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6],c=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
      @fact @select(@larr(a=collect(1:100),b=enumeration(repmat(collect(1:10),10)), c=enumeration(repmat(collect(1:10),10))), by[:b,:c], :a=>sum(_a), where[broadcast(>, _a, 56)]) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6],c=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
    end
  end
  context("selct tests") do
    context("aggregate tests") do
      @fact selct(lar,:c2,:c3).data --> pick(lar,[:c2,:c3])
      @fact selct(lar,c2=d->broadcast(*, d[:c2], 2),:c3).data --> reorder(@darr(c2=2*pick(lar,:c2),c3=pick(lar,(:c3,))[1]), :c3)
      @fact selct(lar,c2=d->broadcast(*, d[:c2], 2),:c3) --> reorder(@select(lar,c2=broadcast(*, _[:c2], 2),:c3), :c3)
    end
    context("condition tests") do
      @fact selct(lar, where=d->broadcast(<, 10.0, d[:c2]) & broadcast(<, d[:c2], 25)) --> begin
        base = @larr(c1=col1[1:10,2:3],c2=col2[1:10,2:3],c3=col3[1:10,2:3],c4=col4[1:10,2:3],axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        dcube.setna!(base, 5:10, 2)
        base
      end
      @fact selct(lar, c1=d->broadcast(*, d[:c1], 2), where=Any[d->broadcast(<, 10.0, d[:c2]) & broadcast(<, d[:c2], 25)]) --> begin
        base = @larr(c1=broadcast(*, 2, col1[1:10,2:3]),axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        dcube.setna!(base, 5:10, 2)
        base
      end
    end
    context("by tests") do
      @fact size(selct(lar, by=Any[:k1=>d->d[:k2]-d[:c1],:r1], by=:m1=>d->broadcast(>, d[:k2], 205))) --> (500,2)
      @fact size(selct(lar, by=:k1=>d->d[:k2]-d[:k1], by=Any[:m1=>d->broadcast(>, d[:k2], 205)])) --> (1,2)
      @fact selct(lar, by=:k1=>d->d[:k2] - d[:k1], by=Any[:m1=>d->broadcast(>, d[:k2], 205)], c1=d->sum(igna(d[:c1]))) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f1 = fld -> sum(igna(fld))
      @fact selct(lar, by=:k1=>d->d[:k2]-d[:k1], by=:m1=>d->broadcast(>, d[:k2], 205), c1=d->f1(d[:c1])) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f2 = d -> sum(igna(d[:c1]))
      @fact selct(lar, by=Any[:k1=>d->d[:k2]-d[:k1]], by=:m1=>d->broadcast(>, d[:k2], 205), c1=d->f2(d)) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      @fact size(selct(lar, by=Any[:k1=>d->d[:k2]-d[:c1],:r1], by=:m1=>d->broadcast(>, d[:k2], 205), :c1=>d->broadcast(*, d[:c1], d[:c2]), :c2)) --> (500,2)
      @fact selct(@larr(a=collect(1:100),b=repmat(collect(1:10),10)), by=[:b], :a=>d->sum(d[:a]), where=d->broadcast(>, d[:a], 56)) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
      @fact selct(@darr(a=collect(1:100),b=repmat(collect(1:10),10)), by=[:b], :a=>d->sum(d[:a]), where=d->broadcast(>, d[:a], 56)) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
    end
  end

  context("@update tests") do
    context("aggregate tests") do
      @fact @update(lar,c2=broadcast(*, _c2, 2)) --> (temp=copy(lar);temp.data.data[:c2]=broadcast(*, temp.data.data[:c2], 2);temp)
      @fact @update(lar,c2=broadcast(*, _[:c2], 2)) --> (temp=copy(lar);temp.data.data[:c2]=broadcast(*, temp.data.data[:c2], 2);temp)
    end
    context("condition tests") do
      @fact @update(lar, c1=broadcast(*, _c1, 2), where[broadcast(<, 10, _c2) & broadcast(<, _c2, 25)]) --> begin
        temp = copy(lar)
        inds = ignabool(broadcast(<, 10, temp.data.data[:c2]) & broadcast(<, temp.data.data[:c2], 25))
        temp.data.data[:c1][inds] = broadcast(*, 2, temp.data.data[:c1][inds])
        temp
      end
    end
  end
  context("update tests") do
    context("aggregate tests") do
      @fact update(lar,c2=d->broadcast(*, d[:c2], 2)) --> (temp=copy(lar);temp.data.data[:c2]=broadcast(*, temp.data.data[:c2], 2);temp)
    end
    context("condition tests") do
      @fact update(lar, c1=d->broadcast(*, d[:c1], 2), where=d->broadcast(<,10,d[:c2]) & broadcast(<,d[:c2], 25)) --> begin
        temp = copy(lar)
        inds = ignabool(broadcast(<, 10, temp.data.data[:c2]) & broadcast(<, temp.data.data[:c2], 25))
        temp.data.data[:c1][inds] = broadcast(*, 2, temp.data.data[:c1][inds])
        temp
      end
    end
  end

  context("conversion tests") do
    @fact @select(@darr(a=[1,2,3]),b=[4,5,6]) --> @darr(b=[4,5,6])
    @fact @update(@darr(a=[1,2,3]),b=[4,5,6]) --> @darr(a=[1,2,3],b=[4,5,6])
    @fact @select(@larr(a=[1,2,3]),b=[4,5,6]) --> @larr(b=[4,5,6])
    @fact @update(@larr(a=[1,2,3]),b=[4,5,6]) --> @larr(a=[1,2,3],b=[4,5,6])
  end
  context("@select misc tests") do
    @fact @select(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=_[:a], where[broadcast(>, _a, 2)]) --> @larr(k=[NA NA 3;4 5 6])
    @fact @select(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=_[_c]) -->@larr(k=[1 11 12;13 5 6])
    @fact @select(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=_[_c], where[broadcast(>, _a, 2)]) --> @larr(k=[NA NA 12;13 5 6])
    # test whether sortable byvariables are sorted.
    @fact @select(@larr(a=[1 2 3 4 5],b=[:a :b :a :b :b]), by[:b], r=sum(_a)) --> @larr(axis1[b=[:a,:b]], r=[4,11])
    @fact @select(@larr(a=[1 2 3 4 5],b=[:b :a :a :b :b]), by[:b], r=sum(_a)) --> @larr(axis1[b=[:a,:b]], r=[5,10])
    # test whether unsortable byvariables are unsorted.
    @fact @select(@larr(a=[1 2 3 4 5],b=[Wrap(:a) Wrap(:b) Wrap(:a) Wrap(:b) Wrap(:b)]), by[:b], r=sum(_a)) --> @larr(axis1[b=[Wrap(:a),Wrap(:b)]], r=[4,11])
    @fact @select(@larr(a=[1 2 3 4 5],b=[Wrap(:b) Wrap(:a) Wrap(:a) Wrap(:b) Wrap(:b)]), by[:b], r=sum(_a)) --> @larr(axis1[b=[Wrap(:b),Wrap(:a)]], r=[10,5])
    @fact size(@select(@larr(a=fill(:sym,10),b=[1,1,1,2,2,3,3,3,3,3],c=[1,1,2,2,2,2,2,3,3,3]), by[:b],by[:c])) --> (3,3)
    @fact isna(@select(@larr(a=fill(:sym,10),b=[1,1,1,2,2,3,3,3,3,3],c=[1,1,2,2,2,2,2,3,3,3]), by[:b],by[:c])) --> [false false true;true false true;true false false]
    @fact @select(@larr(a=fill(:sym,10),b=[1,1,1,2,2,3,3,3,3,3],c=[1,1,2,2,2,2,2,3,3,3]), by[:b],by[:c], a=length(_a)) --> @larr(a=[2 1 NA;NA 2 NA;NA 2 3], axis1[b=[1,2,3]], axis2[c=[1,2,3]])
    @fact @select(larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), c=length(_), d=_a) --> reshape(larr(c=fill(6,6), d=[1,4,2,5,3,6]), 2, 3)
    @fact @select(larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), c=length(_), d=_a, where[broadcast(>, _a, 2)]) --> reshape(@larr(c=[NA,4,NA,4,4,4], d=[NA,4,NA,5,3,6]), 2, 3)
    @fact @select(larr([1 2;3 4;5 6],axis1=darr(k=[10,11,12])), where[broadcast(==, _k, 11)]) --> larr([3 4], axis1=darr(k=[11]))
  end
  context("selct misc tests") do
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[:a], where=d->broadcast(>, d[:a], 2)) --> @larr(k=[NA NA 3;4 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[:a], where=Any[d->broadcast(>, d[:a], 2)]) --> @larr(k=[NA NA 3;4 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[:a], where=Any[d->broadcast(>, d[:a], 2)]) --> @larr(k=[NA NA 3;4 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[d[:c]]) -->@larr(k=[1 11 12;13 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[d[:c]], where=d->broadcast(>, d[:a], 2)) --> @larr(k=[NA NA 12;13 5 6])
    # test whether sortable byvariables are sorted.
    @fact selct(@larr(a=[1 2 3 4 5],b=[:a :b :a :b :b]), by=[:b], r=d->sum(d[:a])) --> @larr(axis1[b=[:a,:b]], r=[4,11])
    @fact selct(@larr(a=[1 2 3 4 5],b=[:b :a :a :b :b]), by=:b, r=d->sum(d[:a])) --> @larr(axis1[b=[:a,:b]], r=[5,10])
    # test whether unsortable byvariables are unsorted.
    @fact selct(@larr(a=[1 2 3 4 5],b=[Wrap(:a) Wrap(:b) Wrap(:a) Wrap(:b) Wrap(:b)]), by=[:b], r=d->sum(d[:a])) --> @larr(axis1[b=[Wrap(:a),Wrap(:b)]], r=[4,11])
    @fact selct(@larr(a=[1 2 3 4 5],b=[Wrap(:b) Wrap(:a) Wrap(:a) Wrap(:b) Wrap(:b)]), by=:b, r=d->sum(d[:a])) --> @larr(axis1[b=[Wrap(:b),Wrap(:a)]], r=[10,5])
    @fact size(selct(@larr(a=fill(:sym,10),b=[1,1,1,2,2,3,3,3,3,3],c=[1,1,2,2,2,2,2,3,3,3]), by=:b,by=:c)) --> (3,3)
    @fact isna(selct(@larr(a=fill(:sym,10),b=[1,1,1,2,2,3,3,3,3,3],c=[1,1,2,2,2,2,2,3,3,3]), by=:b,by=[:c])) --> [false false true;true false true;true false false]
    @fact selct(@larr(a=fill(:sym,10),b=[1,1,1,2,2,3,3,3,3,3],c=[1,1,2,2,2,2,2,3,3,3]), by=[:b],by=:c, :a=>d->length(d[:a])) --> @larr(a=[2 1 NA;NA 2 NA;NA 2 3], axis1[b=[1,2,3]], axis2[c=[1,2,3]])
    @fact selct(larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), :c=>d->length(d), d=d->d[:a]) --> reshape(larr(c=fill(6,6), d=[1,4,2,5,3,6]), 2, 3)
    # note the reversal of order because the keyword arguments come after pair arguments.
    @fact selct(larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), c=d->length(d), :d=>d->d[:a], where=d->broadcast(>, d[:a], 2)) --> reshape(@larr(d=[NA,4,NA,5,3,6],c=[NA,4,NA,4,4,4]), 2, 3)
    @fact selct(larr([1 2;3 4;5 6],axis1=darr(k=[10,11,12])), where=Any[d->broadcast(==, d[:k], 11)]) --> larr([3 4], axis1=darr(k=[11]))
  end
  context("misc @update misc tests") do
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3]),a=mean(_a), by[:b]) --> larr(a=[2.0,2.0,2.0,4.5,4.5,8.0,8.0,8.0,8.0,8.0], b=[1,1,1,2,2,3,3,3,3,3])
    # TODO a=1:10 was fine in julia v0.5. In v0.6, the int type complains if we update it using a = mean(_a).
    @fact @update(larr(a=1.0*1:10, b=[1,1,1,2,2,3,3,3,3,3]),a=mean(_a), by[:b]) --> larr(a=[2.0,2.0,2.0,4.5,4.5,8.0,8.0,8.0,8.0,8.0], b=[1,1,1,2,2,3,3,3,3,3])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c]) --> larr(a=[1.0,2.0,3.0,4.0,5.0,8.0,7.0,8.0,9.0,8.0], b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=1.0*1:10, b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c]) --> larr(a=[1.0,2.0,3.0,4.0,5.0,8.0,7.0,8.0,9.0,8.0], b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c]) --> @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b], by[:c])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),ma=mean(_a), by[:b,:c]) --> larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12], ma=1.0*[1,2,3,4,5,8,7,8,9,8])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),ma=reverse(_a), by[:b,:c]) --> larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12], ma=1.0*[1,2,3,4,5,10,7,8,9,6])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3],c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c], where[broadcast(<=, _c, 12)]) --> larr(a=1.0*[1,2,3,4,5,8,7,8,9,8],b=[1,1,1,2,2,3,3,3,3,3],c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=collect(1.0*(1:10)),c=[11,12,13,14,11,12,13,14,11,12]),a=reverse(_a), by[:c], where[broadcast(<=, _c, 12)]) --> larr(a=1.0*[9,10,3,4,5,6,7,8,1,2], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=1.0*1:10,c=enumeration([11,12,13,14,11,12,13,14,11,12])),a=1.0*reverse(_a), by[:c], where[broadcast(<=, _c, 12)]) --> larr(a=1.0*[9,10,3,4,5,6,7,8,1,2], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=collect(1.0*(1:10)),c=enumeration([11,12,13,14,11,12,13,14,11,12])),ma=mean(_a), a=reverse(_a), by[:c], where[broadcast(<=, _c, 12)]) --> @larr(a=1.0*[9,10,3,4,5,6,7,8,1,2], c=[11,12,13,14,11,12,13,14,11,12], ma=[5.0,6.0,NA,NA,5.0,6.0,NA,NA,5.0,6.0])
    @fact @update(darr(a=1.0*[1,2,3,4,5],b=[1,1,2,2,2]),by[b=broadcast(*, _b, 2)],a=reverse(_a),where[broadcast(<, _a, 5)]) --> darr(a=[2,1,4,3,5],b=[1,1,2,2,2])
    @fact @update(darr(a=1.0*[1,2,3,4,5],b=enumeration([1,1,2,2,2])),by[b=broadcast(*, _b, 2)],a=mean(_a),where[broadcast(<, _a, 5)]) --> darr(a=[1.5,1.5,3.5,3.5,5.0],b=[1,1,2,2,2])
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),by[b=broadcast(*, _b, 2)],c=mean(_a),where[broadcast(<, _a, 5)]) --> reorder(@darr(c=[1.5,1.5,3.5,3.5,NA],b=[1,1,2,2,2],a=[1,2,3,4,5]), :a,:b,:c)
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),c=_a*2.0,where[broadcast(<, _a, 5)]) --> darr(a=[1,2,3,4,5],b=[1,1,2,2,2],c=@nalift([2.0,4.0,6.0,8.0,NA]))
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),c=mean(_a),where[broadcast(<, _a, 5)]) --> darr(a=[1,2,3,4,5],b=[1,1,2,2,2],c=@nalift([2.5,2.5,2.5,2.5,NA]))
    # Let's think about this is okay, where we just return the original labeled array when there is nothing to update.
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),c=mean(_a),where[broadcast(<, _a, 5)],where[broadcast(>, _a, 5)]) --> darr(a=[1,2,3,4,5],b=[1,1,2,2,2])
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2])) --> darr(a=[1,2,3,4,5],b=[1,1,2,2,2])
    @fact update(@larr(a=1:10, b=[1,2,3,NA,NA,NA,1,1,2,3], c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z]), a=d->sum(d[:a]), d=d->reverse(broadcast(*, d[:a], d[:b])), where=[d-> ~isna(d[:b])], by=[:b]) --> @larr(a=[16,11,13,4,5,6,16,16,11,13],b=[1,2,3,NA,NA,NA,1,1,2,3],c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z],d=[8,18,30,NA,NA,NA,7,1,4,9])
    @fact @select(larr(a=[1,1,2,3,4],b=enumeration([:a,:a,:b,:b,:b])), ct=length(_), by[:b]) --> larr(axis1=darr(b=[:a,:b]), ct=[2,3])
    @fact typeof(pickaxis(@select(larr(a=[1,1,2,3,4],b=enumeration([:a,:a,:b,:b,:b])), ct=length(_), by[:b]),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Symbol},1,DataCubes.EnumerationArray{Symbol,1,Array{Int64,1},Int64}},Nullable{Symbol}}
    @fact @select(larr(a=[1,1,2,3,4],b=enumeration([1.0,1.0,2.0,1.0,2.0])), ct=length(_), by[:b]) --> @larr(axis1[b=[1.0,2.0]], ct=[3,2])
    @fact (@rap typeof pickaxis(_,1) @select(larr(a=[1,1,2,3,4],b=enumeration([1.0,1.0,2.0,1.0,2.0])), ct=length(_), by[:b])) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Float64},1,DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}},Nullable{Float64}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[:r], s=sum(_a)) --> @larr(axis1[r=[:a,:b]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[:r], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Symbol},1,DataCubes.EnumerationArray{Symbol,1,Array{Int64,1},Int64}},Nullable{Symbol}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[r=map(x->string(x.value),_r)], s=sum(_a)) --> @larr(axis1[r=["a","b"]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[r=map(x->string(x.value),_r)], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{String},1,Array{Nullable{String},1}},Nullable{String}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[:r], s=sum(_a)) --> @larr(axis1[r=[1.0,2.0]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[:r], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Float64},1,DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}},Nullable{Float64}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[r=broadcast(*, _r, 2)], s=sum(_a)) --> @larr(axis1[r=[2.0,4.0]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[r=broadcast(*,_r, 2)], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Float64},1,DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}},Nullable{Float64}}
    @fact typeof(view(@select(larr(a=rand(5,3),axis2=darr(r=enumeration([:X,:Y,:Z]))),:r),2,1:2).data.data[:r]) -->  typeof(view(@select(larr(a=rand(5,3),axis2=darr(r=enumeration([:X,:Y,:Z]))),:r),2,1:2).data.data[:r])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r,r5=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z'],r5=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r,r5=_r,r6=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z'],r5=['X','Y','Z'],r6=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r,r5=_r,r6=_r,r7=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z'],r5=['X','Y','Z'],r6=['X','Y','Z'],r7=['X','Y','Z']), s=[5,7,9])
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10_000), by[:a], s=msum(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10_000), by[:a], s=msum(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mprod(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mprod(_b, rev=true, window=10))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmean(_b, window=10))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmean(_b, window=1))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mminimum(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mminimum(_b, 1, window=10))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmaximum(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmaximum(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmedian(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmedian(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmiddle(_b, 1, rev=true))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmiddle(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.2, window=20))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.5))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.1, rev=true))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.8, rev=true))) --> (10000,)
  end
  context("misc tests") do
    @fact @select(larr(a=[1,1,2,3,4],b=enumeration([:a,:a,:b,:b,:b])), ct=length(_), by[:b]) --> larr(axis1=darr(b=[:a,:b]), ct=[2,3])
    @fact typeof(pickaxis(@select(larr(a=[1,1,2,3,4],b=enumeration([:a,:a,:b,:b,:b])), ct=length(_), by[:b]),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Symbol},1,DataCubes.EnumerationArray{Symbol,1,Array{Int64,1},Int64}},Nullable{Symbol}}
    @fact @select(larr(a=[1,1,2,3,4],b=enumeration([1.0,1.0,2.0,1.0,2.0])), ct=length(_), by[:b]) --> @larr(axis1[b=[1.0,2.0]], ct=[3,2])
    @fact (@rap typeof pickaxis(_,1) @select(larr(a=[1,1,2,3,4],b=enumeration([1.0,1.0,2.0,1.0,2.0])), ct=length(_), by[:b])) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Float64},1,DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}},Nullable{Float64}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[:r], s=sum(_a)) --> @larr(axis1[r=[:a,:b]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[:r], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Symbol},1,DataCubes.EnumerationArray{Symbol,1,Array{Int64,1},Int64}},Nullable{Symbol}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[r=map(x->string(x.value),_r)], s=sum(_a)) --> @larr(axis1[r=["a","b"]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=enumeration([:a,:a,:b]))), by[r=map(x->string(x.value),_r)], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{String},1,Array{Nullable{String},1}},Nullable{String}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[:r], s=sum(_a)) --> @larr(axis1[r=[1.0,2.0]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[:r], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Float64},1,DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}},Nullable{Float64}}
    @fact @select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[r=broadcast(*, _r, 2)], s=sum(_a)) --> @larr(axis1[r=[2.0,4.0]], s=[12,9])
    @fact typeof(pickaxis(@select(larr(a=[1 2 3;4 5 6], axis2=darr(r=[1.0,1.0,2.0])), by[r=broadcast(*, _r, 2)], s=sum(_a)),1)) --> DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Float64},1,DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}},Nullable{Float64}}
    @fact typeof(view(@select(larr(a=rand(5,3),axis2=darr(r=enumeration([:X,:Y,:Z]))),:r),2,1:2).data.data[:r]) -->  typeof(view(@select(larr(a=rand(5,3),axis2=darr(r=enumeration([:X,:Y,:Z]))),:r),2,1:2).data.data[:r])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r,r5=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z'],r5=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r,r5=_r,r6=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z'],r5=['X','Y','Z'],r6=['X','Y','Z']), s=[5,7,9])
    @fact @select(@larr(a=[1 2 3;4 5 6], axis1[k=[:a,:b]], axis2[r=['X','Y','Z']]), by[:r,:r1=>_r,r2=_r,:r3=>_r,:r4=>_r,r5=_r,r6=_r,r7=_r], s=sum(_a)) --> larr(axis1=darr(r=['X','Y','Z'],r1=['X','Y','Z'],r2=['X','Y','Z'],r3=['X','Y','Z'],r4=['X','Y','Z'],r5=['X','Y','Z'],r6=['X','Y','Z'],r7=['X','Y','Z']), s=[5,7,9])
    @fact @update(darr(a=["a" "b" "cd";"efg" "h" "ij"]), b=length(_a)) --> darr(a=["a" "b" "cd";"efg" "h" "ij"], b=fill(6,2,3))
    @fact @update(larr(a=["a" "b" "cd";"efg" "h" "ij"],axis1=[:x,:y]), b=length(_a)) --> larr(a=["a" "b" "cd";"efg" "h" "ij"], b=fill(6,2,3), axis=[:x,:y])
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10_000), by[:a], s=msum(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10_000), by[:a], s=msum(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mprod(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mprod(_b, rev=true, window=10))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmean(_b, window=10))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmean(_b, window=1))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mminimum(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mminimum(_b, 1, window=10))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmaximum(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmaximum(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmedian(_b))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmedian(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmiddle(_b, 1, rev=true))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mmiddle(_b))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.2, window=20))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.5))) --> (10000,)
    @fact size(@select(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.1, rev=true))) --> (100,)
    @fact size(@update(darr(a=repmat(1:100,100),b=1.0*1:10000), by[:a], s=mquantile(_b, 0.8, rev=true))) --> (10000,)
  end
end

end
