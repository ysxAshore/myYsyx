#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>

void init_regex();
word_t expr(char *e, bool *success);

void init_wp_pool();
void deleteWatchPoint(int NO);
void displayWatchPoint();
void createWatchPoint(char *args);

#endif
