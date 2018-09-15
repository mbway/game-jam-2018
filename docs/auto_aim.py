#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
from numpy import pi

def main():
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))

    x = np.linspace(-pi*0.75, pi*0.75, num=200)

    start_influence = 0.1 # [0,1]
    max_influence = 0.8 # [0,1]
    start_diff = 1 # rad

    def influence(power):
        width = -np.log(start_influence/max_influence)/(start_diff**power)
        return max_influence * np.exp(-width*(x**power))

    ax1.axhline(y=max_influence, c='r', linestyle=':', alpha=0.5, label='max_influence')
    ax1.axhline(y=start_influence, c='b', linestyle=':', alpha=0.5, label='start_influence')
    ax1.axvline(x=start_diff, c='grey', linestyle='--', alpha=0.5, label=r'$\pm$start_diff')
    ax1.axvline(x=-start_diff, c='grey', linestyle='--', alpha=0.5)
    ax1.plot(x, influence(2), label='influence (power=2)')
    ax1.plot(x, influence(4), label='influence (power=4)')
    ax1.plot(x, influence(6), label='influence (power=6)')
    ax1.set_ylim((-0.01, 1))
    ax1.legend()
    ax1.set_ylabel('auto aim influence')
    ax1.set_xlabel('angle difference (rads)')
    ax1.set_title('Auto Aim Influence')

    x = np.linspace(0, 1, num=200)
    max_start_diff_multiply = 4

    def start_diff_mul(xs):
        return (max_start_diff_multiply-1)*np.exp(-8*xs)+1

    ax2.plot(x, start_diff_mul(x), label='multiplier')
    x = np.linspace(-0.2, 0, num=100)
    ax2.plot(x, start_diff_mul(x), c='grey', linestyle=':')
    ax2.axvline(x=0, c='k')
    ax2.axhline(y=max_start_diff_multiply, c='grey', linestyle='--', label='max_start_diff_multiply')
    ax2.axhline(y=1, c='grey', linestyle='--', label='1.0')
    ax2.set_ylim((0, max_start_diff_multiply+1))
    ax2.legend()
    ax2.set_ylabel('multiplier')
    ax2.set_xlabel('subtended angle (rads)')
    ax2.set_title('Auto Aim start_diff multiplier')

    fig.tight_layout()
    fig.savefig('auto_aim.pdf', bbox_inches='tight')
    fig.savefig('auto_aim.png', dpi=100, bbox_inches='tight')
    plt.show()

if __name__ == '__main__':
    main()

