/*
 * Implementation of the hash table type.
 *
 * Author : Stephen Smalley, <sds@epoch.ncsc.mil>
 */
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/errno.h>
#include "hashtab.h"

struct hashtab *hashtab_create(u32 size)
{
	struct hashtab *p;
	u32 i;

	p = kzalloc(sizeof(*p), GFP_KERNEL);
	if (p == NULL)
		return p;

	p->size = size;
	p->nel = 0;
	p->htable = kmalloc(sizeof(*(p->htable)) * size, GFP_KERNEL);
	if (p->htable == NULL) {
		kfree(p);
		return NULL;
	}

	for (i = 0; i < size; i++)
		p->htable[i] = NULL;

	return p;
}

int __hashtab_insert(struct hashtab *h, struct hashtab_node **dst,
		     void *key, void *datum)
{
	struct hashtab_node *newnode;

	newnode = kzalloc(sizeof(*newnode), GFP_KERNEL);
	if (newnode == NULL)
		return -ENOMEM;
	newnode->key = key;
	newnode->datum = datum;
	
	newnode->next = *dst;
	*dst = newnode;

	h->nel++;
	return 0;
}

void hashtab_destroy(struct hashtab *h)
{
	u32 i;
	struct hashtab_node *cur, *temp;

	if (!h)
		return;

	for (i = 0; i < h->size; i++) {
		cur = h->htable[i];
		while (cur) {
			temp = cur;
			cur = cur->next;
			kfree(temp);
		}
		h->htable[i] = NULL;
	}

	kfree(h->htable);
	h->htable = NULL;

	kfree(h);
}

int hashtab_map(struct hashtab *h,
		int (*apply)(void *k, void *d, void *args),
		void *args)
{
	u32 i;
	int ret;
	struct hashtab_node *cur;

	if (!h)
		return 0;

	for (i = 0; i < h->size; i++) {
		cur = h->htable[i];
		while (cur) {
			ret = apply(cur->key, cur->datum, args);
			if (ret)
				return ret;
			cur = cur->next;
		}
	}
	return 0;
}


void hashtab_stat(struct hashtab *h, struct hashtab_info *info)
{
	u32 i, chain_len, slots_used, max_chain_len;
	struct hashtab_node *cur;

	slots_used = 0;
	max_chain_len = 0;
	for (slots_used = max_chain_len = i = 0; i < h->size; i++) {
		cur = h->htable[i];
		if (cur) {
			slots_used++;
			chain_len = 0;
			while (cur) {
				chain_len++;
				cur = cur->next;
			}

			if (chain_len > max_chain_len)
				max_chain_len = chain_len;
		}
	}

	info->slots_used = slots_used;
	info->max_chain_len = max_chain_len;
}
