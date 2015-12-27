module TestSelect

using FactCheck
using MultidimensionalTables

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
    context("aggregate tests") do
      @fact @select(lar,:c2,:c3).data --> pick(lar,[:c2,:c3])
      @fact @select(lar,c2=_c2 .* 2,:c3).data --> @darr(c2=2*pick(lar,:c2),c3=pick(lar,:c3))
      @fact @select(lar,c2=_c2 .* 2,:c3) --> @select(lar,c2=_[:c2].*2,:c3)
    end
    context("condition tests") do
      @fact @select(lar, where[10 .< _c2 .< 25]) --> begin
        base = @larr(c1=col1[1:10,2:3],c2=col2[1:10,2:3],c3=col3[1:10,2:3],c4=col4[1:10,2:3],axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        tbltool.setna!(base, 5:10, 2)
        base
      end
      @fact @select(lar, c1=_c1 .* 2, where[10 .< _c2 .< 25]) --> begin
        base = @larr(c1=2 .* col1[1:10,2:3],axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        tbltool.setna!(base, 5:10, 2)
        base
      end
    end
    context("by tests") do
      @fact size(@select(lar, by[k1=_k2 - _c1,:r1], by[m1=_k2 .> 205])) --> (500,2)
      @fact size(@select(lar, by[k1=_k2 - _k1], by[m1=_k2 .> 205])) --> (1,2)
      @fact @select(lar, by[k1=_k2 - _k1], by[m1=_k2 .> 205], c1=sum(igna(_c1))) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f1 = fld -> sum(igna(fld))
      @fact @select(lar, by[k1=_k2 - _k1], by[m1=_k2 .> 205], c1=f1(_c1)) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f2 = d -> sum(igna(d[:c1]))
      @fact @select(lar, by[k1=_k2 - _k1], by[m1=_k2 .> 205], c1=f2(_)) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      @fact size(@select(lar, by[k1=_k2 - _c1,:r1], by[m1=_k2 .> 205], c1= _c1 .* _c2, :c2)) --> (500,2)
      @fact @select(@larr(a=collect(1:100),b=repmat(collect(1:10),10)), by[:b], :a=>sum(_a), where[_a.>56]) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
    end
  end
  context("selct tests") do
    context("aggregate tests") do
      @fact selct(lar,:c2,:c3).data --> pick(lar,[:c2,:c3])
      @fact selct(lar,c2=d->d[:c2] .* 2,:c3).data --> reorder(@darr(c2=2*pick(lar,:c2),c3=pick(lar,(:c3,))[1]), :c3)
      @fact selct(lar,c2=d->d[:c2] .* 2,:c3) --> reorder(@select(lar,c2=_[:c2].*2,:c3), :c3)
    end
    context("condition tests") do
      @fact selct(lar, where=d->10.0 .< d[:c2] .< 25) --> begin
        base = @larr(c1=col1[1:10,2:3],c2=col2[1:10,2:3],c3=col3[1:10,2:3],c4=col4[1:10,2:3],axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        tbltool.setna!(base, 5:10, 2)
        base
      end
      @fact selct(lar, c1=d->d[:c1] .* 2, where=Any[d->10 .< d[:c2] .< 25.0]) --> begin
        base = @larr(c1=2 .* col1[1:10,2:3],axis1[k1=collect(101:110),k2=collect(201:210)],axis2[r1=["a_2","a_3"]])
        tbltool.setna!(base, 5:10, 2)
        base
      end
    end
    context("by tests") do
      @fact size(selct(lar, by=Any[:k1=>d->d[:k2]-d[:c1],:r1], by=:m1=>d->d[:k2] .> 205)) --> (500,2)
      @fact size(selct(lar, by=:k1=>d->d[:k2]-d[:k1], by=Any[:m1=>d->d[:k2] .> 205])) --> (1,2)
      @fact selct(lar, by=:k1=>d->d[:k2] - d[:k1], by=Any[:m1=>d->d[:k2] .> 205], c1=d->sum(igna(d[:c1]))) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f1 = fld -> sum(igna(fld))
      @fact selct(lar, by=:k1=>d->d[:k2]-d[:k1], by=:m1=>d->d[:k2] .> 205, c1=d->f1(d[:c1])) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      f2 = d -> sum(igna(d[:c1]))
      @fact selct(lar, by=Any[:k1=>d->d[:k2]-d[:k1]], by=:m1=>d->d[:k2] .> 205, c1=d->f2(d)) --> @larr(c1=[63250 62000],axis1[k1=[100]],axis2[m1=[false,true]])
      @fact size(selct(lar, by=Any[:k1=>d->d[:k2]-d[:c1],:r1], by=:m1=>d->d[:k2] .> 205, :c1=>d->d[:c1] .* d[:c2], :c2)) --> (500,2)
      @fact selct(@larr(a=collect(1:100),b=repmat(collect(1:10),10)), by=[:b], :a=>d->sum(d[:a]), where=d->d[:a].>56) --> sort(@larr(a=[385,390,395,400,304,308,312,316,320,324],axis1[b=[7,8,9,10,1,2,3,4,5,6]]), 1, :b)
    end
  end

  context("@update tests") do
    context("aggregate tests") do
      @fact @update(lar,c2=_c2 .* 2) --> (temp=copy(lar);temp.data.data[:c2]=temp.data.data[:c2] .* 2;temp)
      @fact @update(lar,c2=_[:c2] .* 2) --> (temp=copy(lar);temp.data.data[:c2]=temp.data.data[:c2] .* 2;temp)
    end
    context("condition tests") do
      @fact @update(lar, c1=_c1 .* 2, where[10 .< _c2 .< 25]) --> begin
        temp = copy(lar)
        inds = ignabool(10 .< temp.data.data[:c2] .< 25)
        temp.data.data[:c1][inds] = 2 .* temp.data.data[:c1][inds]
        temp
      end
    end
  end
  context("update tests") do
    context("aggregate tests") do
      @fact update(lar,c2=d->d[:c2] .* 2) --> (temp=copy(lar);temp.data.data[:c2]=temp.data.data[:c2] .* 2;temp)
    end
    context("condition tests") do
      @fact update(lar, c1=d->d[:c1] .* 2, where=d->10 .< d[:c2] .< 25) --> begin
        temp = copy(lar)
        inds = ignabool(10 .< temp.data.data[:c2] .< 25)
        temp.data.data[:c1][inds] = 2 .* temp.data.data[:c1][inds]
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
    @fact @select(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=_[:a], where[_a.>2]) --> @larr(k=[NA NA 3;4 5 6])
    @fact @select(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=_[_c]) -->@larr(k=[1 11 12;13 5 6])
    @fact @select(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=_[_c], where[_a .> 2]) --> @larr(k=[NA NA 12;13 5 6])
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
    @fact @select(larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), c=length(_), d=_a, where[_a.>2]) --> reshape(@larr(c=[NA,4,NA,4,4,4], d=[NA,4,NA,5,3,6]), 2, 3)
    @fact @select(larr([1 2;3 4;5 6],axis1=darr(k=[10,11,12])), where[_k .== 11]) --> larr([3 4], axis1=darr(k=[11]))
  end
  context("selct misc tests") do
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[:a], where=d->d[:a].>2) --> @larr(k=[NA NA 3;4 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[:a], where=Any[d->d[:a].>2]) --> @larr(k=[NA NA 3;4 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[:a], where=Any[d->d[:a].>2]) --> @larr(k=[NA NA 3;4 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[d[:c]]) -->@larr(k=[1 11 12;13 5 6])
    @fact selct(@larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],c=[:a :b :b;:b :a :a]), k=d->d[d[:c]], where=d->d[:a] .> 2) --> @larr(k=[NA NA 12;13 5 6])
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
    @fact selct(larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), c=d->length(d), :d=>d->d[:a], where=d->d[:a].>2) --> reshape(@larr(d=[NA,4,NA,5,3,6],c=[NA,4,NA,4,4,4]), 2, 3)
    @fact selct(larr([1 2;3 4;5 6],axis1=darr(k=[10,11,12])), where=Any[d->d[:k] .== 11]) --> larr([3 4], axis1=darr(k=[11]))
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3]),a=mean(_a), by[:b]) --> larr(a=[2.0,2.0,2.0,4.5,4.5,8.0,8.0,8.0,8.0,8.0], b=[1,1,1,2,2,3,3,3,3,3])
    @fact @update(larr(a=1:10, b=[1,1,1,2,2,3,3,3,3,3]),a=mean(_a), by[:b]) --> larr(a=[2.0,2.0,2.0,4.5,4.5,8.0,8.0,8.0,8.0,8.0], b=[1,1,1,2,2,3,3,3,3,3])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c]) --> larr(a=[1.0,2.0,3.0,4.0,5.0,8.0,7.0,8.0,9.0,8.0], b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=1:10, b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c]) --> larr(a=[1.0,2.0,3.0,4.0,5.0,8.0,7.0,8.0,9.0,8.0], b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c]) --> @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b], by[:c])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),ma=mean(_a), by[:b,:c]) --> larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12], ma=1.0*[1,2,3,4,5,8,7,8,9,8])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12]),ma=reverse(_a), by[:b,:c]) --> larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3], c=[11,12,13,14,11,12,13,14,11,12], ma=1.0*[1,2,3,4,5,10,7,8,9,6])
    @fact @update(larr(a=collect(1.0*(1:10)), b=[1,1,1,2,2,3,3,3,3,3],c=[11,12,13,14,11,12,13,14,11,12]),a=mean(_a), by[:b,:c], where[_c .<= 12]) --> larr(a=1.0*[1,2,3,4,5,8,7,8,9,8],b=[1,1,1,2,2,3,3,3,3,3],c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=collect(1.0*(1:10)),c=[11,12,13,14,11,12,13,14,11,12]),a=reverse(_a), by[:c], where[_c .<= 12]) --> larr(a=1.0*[9,10,3,4,5,6,7,8,1,2], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=1:10,c=[11,12,13,14,11,12,13,14,11,12]),a=1.0*reverse(_a), by[:c], where[_c .<= 12]) --> larr(a=1.0*[9,10,3,4,5,6,7,8,1,2], c=[11,12,13,14,11,12,13,14,11,12])
    @fact @update(larr(a=collect(1.0*(1:10)),c=[11,12,13,14,11,12,13,14,11,12]),ma=mean(_a), a=reverse(_a), by[:c], where[_c .<= 12]) --> @larr(a=1.0*[9,10,3,4,5,6,7,8,1,2], c=[11,12,13,14,11,12,13,14,11,12], ma=[5.0,6.0,NA,NA,5.0,6.0,NA,NA,5.0,6.0])
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),by[b=_b.*2],a=reverse(_a),where[_a.<5]) --> darr(a=[2,1,4,3,5],b=[1,1,2,2,2])
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),by[b=_b.*2],a=mean(_a),where[_a.<5]) --> darr(a=[1.5,1.5,3.5,3.5,5.0],b=[1,1,2,2,2])
    @fact @update(darr(a=[1,2,3,4,5],b=[1,1,2,2,2]),by[b=_b.*2],c=mean(_a),where[_a.<5]) --> reorder(@darr(c=[1.5,1.5,3.5,3.5,NA],b=[1,1,2,2,2],a=[1,2,3,4,5]), :a,:b,:c)
    @fact update(@larr(a=1:10, b=[1,2,3,NA,NA,NA,1,1,2,3], c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z]), a=d->sum(d[:a]), d=d->reverse(d[:a] .* d[:b]), where=[d-> ~isna(d[:b])], by=[:b]) --> @larr(a=[16,11,13,4,5,6,16,16,11,13],b=[1,2,3,NA,NA,NA,1,1,2,3],c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z],d=[8,18,30,NA,NA,NA,7,1,4,9])
  end

end

end
