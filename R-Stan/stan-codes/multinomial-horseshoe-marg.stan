//
// This Stan program defines a Dirichlet Multinomial model, with a
// matrix of values 'Y' modeled as GDM distributed
// with horseshoe prior on beta coefficients 
// ** Wadsworth's model - with HS instead of Spike-Slab**
//

functions {
// for likelihood estimation
  real dirichlet_multinomial_lpmf(int[] y, vector alpha) {
    real alpha_plus = sum(alpha);
    return lgamma(alpha_plus) + lgamma(sum(y)+1) + sum(lgamma(alpha + to_vector(y)))
                - lgamma(alpha_plus+sum(y)) - sum(lgamma(alpha))-sum(lgamma(to_vector(y)+1));
  }
}

data {
  int<lower=1> N; // total number of observations
  int<lower=2> ncolY; // number of categories
  int<lower=2> ncolX; // number of predictor levels
  matrix[N,ncolX] X; // predictor design matrix
  int <lower=0> Y[N,ncolY]; // data // response variable
  real<lower=0> scale_icept;
  // real<lower=0> sd_prior;
  real<lower=0> psi;
}
parameters {
  matrix[ncolX, ncolY] beta_raw; // coefficients (raw)
  vector[N] beta0; // intercept
  matrix<lower=0>[ncolX,ncolY] lambda_tilde; // truncated local shrinkage
  vector<lower=0>[ncolY] tau; // global shrinkage
  real<lower=0> sigma;
  // real<lower = 0> psi;
}
transformed parameters{
  matrix[ncolX,ncolY] beta; // coefficients 
  matrix<lower=0>[ncolX,ncolY] lambda; // local shrinkage
  lambda = diag_post_multiply(lambda_tilde, tau);
  beta = beta_raw .* lambda*sigma;
}

model {
 // psi ~ uniform(0,1);
 sigma ~ inv_gamma(0.5, 0.5);
// prior:
for(k in 1:N){
  beta0[k] ~ cauchy(0, scale_icept);
}
for (k in 1:ncolX) {
      for (l in 1:ncolY) {
        tau[l] ~ cauchy(0, 1); // flexible 
        lambda_tilde[k,l] ~ cauchy(0, 1);
        beta_raw[k,l] ~ normal(0,1);
    }
  }
// likelihood
for (i in 1:N) {
    vector[ncolY] logits;
    for (j in 1:ncolY){
      logits[j] = beta0[i]+X[i,] * beta[,j];
      }
     Y[i,] ~ dirichlet_multinomial(softmax(logits)*(1-psi)/psi);
    }
}

