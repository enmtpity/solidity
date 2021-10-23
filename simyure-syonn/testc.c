#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "SFMT.h"
static sfmt_t sfmt;
//cccp1回分試行
uint32_t my_rand() {
    return sfmt_genrand_uint32( &sfmt );
}

void my_srand( uint32_t seed ) {
    sfmt_init_gen_rand( &sfmt, seed );
}


int r=1;

int exec_slot(int *na, int *nb, int *nc, int m)
{
    my_srand((unsigned int)time(NULL)+r);

    int a = na[0] + nb[0] + nc[0];

    int b = my_rand() % a + 1;

   

    if (b <= na[0])
    {
        na[m + 1] = na[m] - 1;
        nb[m + 1] = nb[m];
        nc[m + 1] = nc[m];
    }
    else if (b <= na[0] + nb[0])
    {
        na[m + 1] = na[m];
        nb[m + 1] = nb[m] - 1;
        nc[m + 1] = nc[m];
    }
    else if (b <= na[0] + nb[0] + nc[0])
    {
        na[m + 1] = na[m];
        nb[m + 1] = nb[m];
        nc[m + 1] = nc[m] - 1;
    }

    r=r+10000;
    m++;
    return m;
}

int main()
{

    int tt[200] = {0}; //期待収益の配列

    int e[200] = {0};  //期待収益
    int na[200] = {0}; //個数
    int nb[200] = {0};
    int nc[200] = {0};

    int ca = 100; //値段
    int cb = 500;
    int cc = 1000;

    int m = 0; //何回目の抽選か

    double pa[200] = {0}; //確率
    double pb[200] = {0};
    double pc[200] = {0};

    int total = 0; //合計収益

    //for (int b = 0; b < 50; b++)
    //{

        m = 0; //何回目の抽選か

         for(int z=0;z<50;z++){
        pa[z]=0;
        pb[z]=0;
        pc[z]=0;
        
    }

        total = 0; //合計収益

        na[0] = 35;
        nb[0] = 10;
        nc[0] = 5;

        pa[0] = (double)na[0] / (na[0] + nb[0] + nc[0]);
        pb[0] = (double)nb[0] / (na[0] + nb[0] + nc[0]);
        pc[0] = (double)nc[0] / (na[0] + nb[0] + nc[0]);

        e[0] = ca * pa[0] + cb * pb[0] + cc * pc[0];
        total += e[0];

        m = exec_slot(na, nb, nc, m);

        for (int i = 1; i < na[0] + nb[0] + nc[0]; i++)
        {
            if (na[i] == 0 || nb[i] == 0 || nc[i] == 0)
            {
               // printf("%d %d %d\n", na[i], nb[i], nc[i]);
                break;
            }
            if (na[i] != 0)
                pa[i] = (double)na[i] / (na[i] + nb[i] + nc[i]);
            if (nb[i] != 0)
                pb[i] = (double)nb[i] / (na[i] + nb[i] + nc[i]);
            if (nc[i] != 0)
                pc[i] = (double)nc[i] / (na[i] + nb[i] + nc[i]);

            e[i] = ca * pa[0] + cb * pb[0] + cc * pc[0];
            total += e[i];

            m = exec_slot(na, nb, nc, m);
        }
        for(int i=0;i<50;i++){
            if(na[i]==0)
            break;
            if(nb[i]==0)
            break;
            if(nc[i]==0)
            break;
            printf("%d\n",na[i]);
        }
         for(int i=0;i<50;i++){
              if(na[i]==0)
            break;
            if(nb[i]==0)
            break;
            if(nc[i]==0)
            break;
            printf("%d\n",nb[i]);
        }
         for(int i=0;i<50;i++){
              if(na[i]==0)
            break;
            if(nb[i]==0)
            break;
            if(nc[i]==0)
            break;
            printf("%d\n",nc[i]);
        }
         for(int i=0;i<50;i++){
              if(na[i]==0)
            break;
            if(nb[i]==0)
            break;
            if(nc[i]==0)
            break;
            printf("%d\n",e[i]);
        }

        /*for(int i=0;i<40;i++){
        printf("%d\n",e[i]);
        
    }*/
        printf("%d\n", total);
    //}

    return 0;
}