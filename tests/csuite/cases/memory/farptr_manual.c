#include <farptr.h>

static ex716_far_ptr target = EX716_FAR_PTR(2U, 0x0200U);
static unsigned short near_word;
static unsigned short source_words[3];
static unsigned short destination_words[3];

int main(void)
{
    ex716_far_put16(&target, 0x1234U);
    near_word = 0x55aaU;
    if (ex716_far_get16(&target) != 0x1234U)
        return 1;
    if (near_word != 0x55aaU)
        return 2;
    ex716_far_put16(&target, 0xbeefU);
    if (ex716_far_get16(&target) != 0xbeefU)
        return 3;
    source_words[0] = 0x1111U;
    source_words[1] = 0x2222U;
    source_words[2] = 0x3333U;
    ex716_far_put16v(&target, source_words, 3U);
    ex716_far_get16v(&target, destination_words, 3U);
    if (destination_words[0] != 0x1111U || destination_words[1] != 0x2222U ||
        destination_words[2] != 0x3333U)
        return 4;
    return near_word == 0x55aaU ? 0 : 5;
}
