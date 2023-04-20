open Brownian;;
open Utils;;
open PolynomialKarhunenLoeveBrownian;;
open List;;
(*
Parabola-ODE method for Stratovitch SDE:
\mathrm{d}y_{t} = f_0(y_t)\mathrm{d}t+f_1(y_t)\circ\mathrm{d}W_t

See theorem 4.3.11, the parabola-ODE method gives
dX_u = f_0(X_u)du + f_1(X_u)d\tilde{W}_u
X_s = y_s

Let W be a standardized brownian motion, let h > 0, and n_int be the number of points we consider inside every intervals [kh,(k+1)h]
The corresponding numerical scheme to obtain Y_{k+1} ~= y_{(k+1}h} from Y_k is

z_0 = Y_k
z_{i+1} = z_i + \sqrt{h}f_1(z_{i}})(\tilde{W}_{i/n_int}-\tilde{W}_{(i-1)/n_int}) + f_0(z_{i})ds
z_{n_int} = Y_{k+1}
where ds = h/n_int.

See the diffusion term is in L^2(P) ~ sqrt(h/n_int) = sqrt(ds), over n_int step, sqrt(h).
Equivalently, we can replace
    (\tilde{W}_{i/n_int}-\tilde{W}_{(i-1)/n_int})~dW=((6-12u)H1/sqrt6 + W1)du
     by setting du = 1/n_int, u = i/n_int
    1/n_int*((6-12i/n_int)H1/sqrt6 + W1)
We still obtain a diffusion term prop. to sqrt(h) after n_int steps.
*)


let oversqrt6 = 0.40824829046386301637;;
let parabola_given_path path f0 f1 y0 n_t t_max =
    let n_int = length path / n_t and h = t_max /. float_of_int n_t in
    let ds = h /. float_of_int n_int and sqrth = sqrt h in
    let oversqrth = 1. /. sqrth and du = 1./.(float_of_int n_int) and eigen_func = jacobi 2. |> eigen 1. in
    let splitted_brownian = split_f path n_t and grid = range 0. du 1. n_int in
    let standardized_brownians =
        map (fun w -> let w0 = hd w in map (fun wt -> oversqrth *. (wt -. w0)) w) splitted_brownian in
    let rec aux accu ongoing_standardized_brownians k =
        if k <= n_t then
            match ongoing_standardized_brownians with
                | current_path::other_paths ->
                let w1 = current_path |> rev |> hd in
                let i1 = eigen_func |> basis 1. n_int current_path ~w1bool:true ~w1:w1 |> hd in
                let space_time_levy_area = oversqrt6 *. i1 in
                                       (*let parabola = parabola_brownian n_int current_path ~w1bool:true ~w1:w1 in*)
                                       match accu with
                                        | yk::_-> (*numerical scheme*)
                                            let sum_integrand = fun pre u -> pre +. (sqrth) *. (f1 pre) *. (w1 +. (6. -. 12. *. u)*.space_time_levy_area)*.du +. (f0 pre)*.ds in
                                            let ykp1 = (fold_left sum_integrand yk grid) in
                                        aux (ykp1::accu) other_paths (k+1)
        else
            rev accu
    in aux [y0] standardized_brownians 1
    ;;
