theory Graph
  imports Graph_Theory.Graph_Theory
begin


lemma pair_inj: "inj (Pair a)" by (intro injI) (rule Pair_inject)

lemma (in graph) inj_on_arc_to_ends [simp]:
  shows "inj_on (arc_to_ends G) (arcs G)"
  using inj_on_arc_to_ends .

lemma inj_imp_inj_on: "inj f \<Longrightarrow> inj_on f A"
  using subset_UNIV by (subst inj_on_subset) blast+

lemma (in nomulti_digraph) arc_ends_card: "card (arcs_ends G) = card (arcs G)"
  using inj_on_arc_to_ends by (simp add: arcs_ends_def card_image)

lemma (in wf_digraph) arc_ends_subset_cartesian: "arcs_ends G \<subseteq> verts G \<times> verts G" by auto

lemma card_pairs:
  assumes "finite A"
  shows "card {(u,v). (u,v)\<in>A\<times>A \<and> u\<noteq>v} = (let n=card A in n*(n-1))"
proof -
  let ?n = "card A"
  define M  where "M  \<equiv> {(u,v). (u,v)\<in>A\<times>A \<and> u\<noteq>v}"
  define M' where "M' \<equiv> {(u,v). (u,v)\<in>A\<times>A \<and> u=v}"
  note defs = M_def M'_def

  have 1: "card A = card M'"
    using bij_betw_same_card[of "\<lambda>x. (x,x)" A M']
    unfolding M'_def bij_betw_def inj_on_def by auto
  have 2: "card (A\<times>A) = ?n * ?n" by (rule card_cartesian_product)

  have "M \<subseteq> A\<times>A" and "M' \<subseteq> A\<times>A" unfolding defs by auto
  hence "finite M" and "finite M'"
    using assms finite_cartesian_product[of A A] finite_subset by blast+
  moreover have "A \<times> A = M \<union> M'" and "M \<inter> M' = {}" unfolding defs by auto
  ultimately have 3: "card (A\<times>A) = card M  + card M'" using card_Un_disjoint by simp

  from 1 2 3 show ?thesis using defs
    by (metis add_diff_cancel_right' diff_mult_distrib2 mult.right_neutral)
qed

(* https://en.wikipedia.org/wiki/Directed_graph#Indegree_and_outdegree *)
lemma (in fin_digraph) out_degree_sum: "sum (out_degree G) (verts G) = card (arcs G)"
proof -
  have 1: "\<forall>v\<in>verts G. \<forall>u\<in>verts G. u\<noteq>v \<longrightarrow> out_arcs G u \<inter> out_arcs G v = {}" by fastforce
  have 2: "finite (verts G)" by simp
  have 3: "\<forall>v\<in>verts G. finite (out_arcs G v)" by blast
  have 4: "arcs G = (\<Union>v\<in>verts G. out_arcs G v)" by auto

  have "sum (out_degree G) (verts G) = (\<Sum>v\<in>verts G. card (out_arcs G v))"
    unfolding out_degree_def ..
  also have "\<dots> = card (\<Union>v\<in>verts G. out_arcs G v)"
    using 1 card_UN_disjoint[OF 2] 3 by fastforce
  also have "\<dots> = card (arcs G)"
    using 4 by simp
  finally show ?thesis .
qed

lemma complete_digraph_altdef:
  "complete_digraph n G \<longleftrightarrow> graph G \<and> n = card (verts G) \<and> (\<forall>v. v \<in> verts G \<longrightarrow> out_degree G v = n - 1)"
  (is "?lhs \<longleftrightarrow> ?rhs")
proof (intro iffI)
  assume ?lhs
  then have lhs1: "graph G" and lhs2: "card (verts G) = n" and lhs3: "arcs_ends G = {(u, v). (u, v) \<in> verts G \<times> verts G \<and> u \<noteq> v}"
    unfolding complete_digraph_def by blast+

  let ?V = "verts G" and ?E = "arcs_ends G" and ?n = "card (verts G)"

  have "\<forall>v. v \<in> verts G \<longrightarrow> out_degree G v = n - 1"
  proof (intro allI impI)
    fix v
    assume "v \<in> verts G"

    have "out_degree G v = card (out_arcs G v)" unfolding out_degree_def ..

    also have "... = card (arc_to_ends G ` out_arcs G v)"
    proof -
      from \<open>graph G\<close> have "inj_on (arc_to_ends G) (arcs G)" by (simp add: graph.inj_on_arc_to_ends)
      then have "inj_on (arc_to_ends G) (out_arcs G v)"
        unfolding out_arcs_def by (subst inj_on_subset) blast+
      with sym[OF card_image] show ?thesis .
    qed

    also have "... = card ((\<lambda>w. (v, w)) ` (?V - {v}))"
    proof -
      have "arc_to_ends G ` out_arcs G v = {(u, w) \<in> ?E. u = v}"
        unfolding out_arcs_def arc_to_ends_def arcs_ends_def by blast
      also have "... = {(u, w) \<in> {(u, v). (u, v) \<in> verts G \<times> verts G \<and> u \<noteq> v}. u = v}"
        unfolding lhs3 ..
      also have "... = {(u, w) \<in> verts G \<times> verts G. u \<noteq> w \<and> u = v}" by simp
      also have "... = {(v, w) | w. w \<in> ?V \<and> v \<noteq> w}" using \<open>v \<in> ?V\<close> by blast
      also have "... = {(v, w) | w. w \<in> ?V - {v}}" by blast
      also have "... = (\<lambda>w. (v, w)) ` (?V - {v})" by blast
      finally show ?thesis by (rule arg_cong)
    qed

    also have "... = card (?V - {v})"
      using pair_inj by (intro card_image) (rule inj_imp_inj_on)

    also have "... = card ?V - 1"
    proof -
      have "card {v} = 1" by simp
      have "finite {v}" and "{v} \<subseteq> ?V" using \<open>v \<in> ?V\<close> by blast+
      with card_Diff_subset[of "{v}"] show ?thesis unfolding \<open>card {v} = 1\<close> .
    qed

    finally show "out_degree G v = n - 1" unfolding \<open>card ?V = n\<close> .
  qed

  with lhs1 and lhs2 show ?rhs by blast
next
  let ?V = "verts G" and ?E = "arcs_ends G"
  assume ?rhs
  then have "graph G" and n_def: "n = card ?V" and *: "v \<in> ?V \<Longrightarrow> out_degree G v = n - 1" for v by blast+

  from \<open>graph G\<close>
  have "loopfree_digraph G" and "wf_digraph G" and "finite ?V" and "nomulti_digraph G" and "fin_digraph G"
    using graph.axioms digraph.axioms fin_digraph.axioms fin_digraph_axioms_def
    by blast+
  then have no_loops: "\<And>e. e \<in> ?E \<Longrightarrow> let (u,v) = e in u\<noteq>v"
    using loopfree_digraph_def loopfree_digraph_axioms_def by fastforce

  have "?E = {(u, v) \<in> ?V\<times>?V. u\<noteq>v}" (is "?E = ?R") proof -
    have "?E \<subseteq> ?R" using no_loops \<open>wf_digraph G\<close> wf_digraph.arc_ends_subset_cartesian by auto
    moreover have "card ?E = card ?R" proof -
      have "card ?E = card (arcs G)"
        using \<open>nomulti_digraph G\<close> nomulti_digraph.arc_ends_card[of G] by simp
      also have "\<dots> = sum (out_degree G) (verts G)"
        using \<open>fin_digraph G\<close> fin_digraph.out_degree_sum[of G] by simp
      also have "\<dots> = n * (n-1)"
        using n_def * by simp
      also have "\<dots> = card ?R"
        using n_def card_pairs[of ?V] \<open>finite ?V\<close> by metis
      finally show "card ?E = card ?R" .
    qed
    moreover have "finite ?R"
      using \<open>finite ?V\<close> finite_cartesian_product[of ?V ?V] finite_subset[of ?R "?V\<times>?V"] by auto
    ultimately show "?E = ?R" using card_subset_eq by simp
  qed
  then show ?lhs unfolding complete_digraph_def using \<open>graph G\<close> n_def by simp
qed


subsection\<open>Trivial Properties of the Empty Graph\<close>

lemma wf_digraph_emptyI: "arcs G = {} \<Longrightarrow> wf_digraph G" by (rule wf_digraph.intro) blast+

lemma fin_digraph_emptyI: "verts G = {} \<Longrightarrow> arcs G = {} \<Longrightarrow> fin_digraph G"
  by (intro fin_digraph.intro fin_digraph_axioms.intro) (rule wf_digraph_emptyI, force+)

lemma loopfree_digraph_emptyI: "arcs G = {} \<Longrightarrow> loopfree_digraph G"
  by (intro loopfree_digraph.intro loopfree_digraph_axioms.intro) (rule wf_digraph_emptyI, blast+)

lemma nomulti_digraph_emptyI: "arcs G = {} \<Longrightarrow> nomulti_digraph G"
  by (intro nomulti_digraph.intro nomulti_digraph_axioms.intro) (rule wf_digraph_emptyI, blast+)

lemma empty_sym: "sym {}" unfolding sym_def by (intro allI impI) blast

lemma sym_digraph_emptyI: "arcs G = {} \<Longrightarrow> sym_digraph G"
proof (intro sym_digraph.intro sym_digraph_axioms.intro)
  assume "arcs G = {}"
  show "symmetric G" unfolding symmetric_def arcs_ends_def \<open>arcs G = {}\<close> image_empty
    by (rule empty_sym)
qed (rule wf_digraph_emptyI)

lemma digraph_emptyI: "\<lbrakk>verts G = {}; arcs G = {}\<rbrakk> \<Longrightarrow> digraph G"
  using fin_digraph_emptyI loopfree_digraph_emptyI nomulti_digraph_emptyI by (rule digraph.intro)

lemma pseudo_graph_emptyI: "\<lbrakk>verts G = {}; arcs G = {}\<rbrakk> \<Longrightarrow> pseudo_graph G"
  using fin_digraph_emptyI sym_digraph_emptyI by (rule pseudo_graph.intro)

lemma graph_emptyI: "\<lbrakk>verts G = {}; arcs G = {}\<rbrakk> \<Longrightarrow> graph G"
  using digraph_emptyI pseudo_graph_emptyI by (rule graph.intro)


end
