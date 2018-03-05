Title: How to compute the inverse normal CDF
Category: Math
Tags: normal, math, statistics, acklam
Date: 2018-03-05 00:37

Once upon a time, Peter John Acklam devised a nice algorithm to approximate the [quantile function](https://en.wikipedia.org/wiki/Quantile_function) (AKA inverse cumulative distribution function, or inverse CDF) of the [normal distribution](https://en.wikipedia.org/wiki/Normal_distribution). He made the algorithm freely available, but unfortunately his page describing it has been timing out for quite a while. So, for reference, here’s a quick overview of his algorithm.

# The Source

“Source” as in “where this all came from”, not as in “source code”. Mr. Acklam originally described his algorithm [here](http://home.online.no/~pjacklam/notes/invnorm). Sadly, unless something changed since I posted this, you’ll not be able to access it. However, you can still view the original contents of his page through the [Wayback Machine](https://web.archive.org/web/20151030215612/http://home.online.no/~pjacklam/notes/invnorm/) (and, by the way, there you’ll find much more information than here).

# About the Inverse Normal CDF

I’ll not say much here, because I don’t want to sound too much like a fool and I really don’t know much about this topic. I just found out, for example, that the inverse normal cumulative distribution function seems to be also known as [probit](https://en.wikipedia.org/wiki/Probit).

Anyway, I guess this function has many uses, but my main personal interest has always been in generating (pseudo) random numbers that follow a normal (Gaussian) distribution. You know, generate a uniformly distributed random number, pass it to the inverse CDF of the desired distribution, and voilà.

Unfortunately, there is no closed form for the inverse normal CDF, so people wanting to generate normally-distributed random numbers usually resort to algorithms like the [Box-Muller Transform](https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform) or [the polar method](https://en.wikipedia.org/wiki/Marsaglia_polar_method). These algorithms are surely good enough for my not so serious needs, but there is something elegant about the inverse CDF method that just fits better to my taste.

So, the point is that, since there is no closed form for the inverse normal CDF, if you need (or want) to use it in a computer program, you’ll probably need to use some kind of approximation. That’s what Acklam’s algorithm does.

# The Algorithm

Here’s the algorithm, just as Acklam’s described it. p is the input, x is the output.

Coefficients in rational approximations.
```c
a(1) <- -3.969683028665376e+01
a(2) <-  2.209460984245205e+02
a(3) <- -2.759285104469687e+02
a(4) <-  1.383577518672690e+02
a(5) <- -3.066479806614716e+01
a(6) <-  2.506628277459239e+00

b(1) <- -5.447609879822406e+01
b(2) <-  1.615858368580409e+02
b(3) <- -1.556989798598866e+02
b(4) <-  6.680131188771972e+01
b(5) <- -1.328068155288572e+01

c(1) <- -7.784894002430293e-03
c(2) <- -3.223964580411365e-01
c(3) <- -2.400758277161838e+00
c(4) <- -2.549732539343734e+00
c(5) <-  4.374664141464968e+00
c(6) <-  2.938163982698783e+00

d(1) <-  7.784695709041462e-03
d(2) <-  3.224671290700398e-01
d(3) <-  2.445134137142996e+00
d(4) <-  3.754408661907416e+00
```
Define break-points.
```c
p_low  <- 0.02425
p_high <- 1 - p_low
```
Rational approximation for lower region.
```c
if 0 < p < p_low
   q <- sqrt(-2*log(p))
   x <- (((((c(1)*q+c(2))*q+c(3))*q+c(4))*q+c(5))*q+c(6)) /
         ((((d(1)*q+d(2))*q+d(3))*q+d(4))*q+1)
endif
```
Rational approximation for central region.
```c
if p_low <= p <= p_high
   q <- p - 0.5
   r <- q*q
   x <- (((((a(1)*r+a(2))*r+a(3))*r+a(4))*r+a(5))*r+a(6))*q /
        (((((b(1)*r+b(2))*r+b(3))*r+b(4))*r+b(5))*r+1)
endif
```
Rational approximation for upper region.
```c
if p_high < p < 1
   q <- sqrt(-2*log(1-p))
   x <- -(((((c(1)*q+c(2))*q+c(3))*q+c(4))*q+c(5))*q+c(6)) /
          ((((d(1)*q+d(2))*q+d(3))*q+d(4))*q+1)
endif
```

#How Good Is It?

I’ll not even try to give my own answer to this question. According to Peter J. Acklam himself, “the absolute value of the relative error is less than 1.15 × 10−9 in the entire region” — relative error being defined as (xapprox - xexact) / xexact. He mentions that the error can be theoretically greater than 1.15 × 10−9 when x < -38, but the probability of seeing this in practice is virtually zero: this would correspond to an input of 2.885428351 × 10−316 or less. Furthermore, he adds, using IEEE double precision arithmetic we cannot even represent numbers like 2.885428351 × 10−316 in full precision, so we would already have an error greater than 1.15 × 10−9 for this reason alone.

Also, someone around the web, says that Acklam’s algorithm has been praised in a book, and so it seems that not only the algorithm’s author thinks it is good.

